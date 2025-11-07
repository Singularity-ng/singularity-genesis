defmodule Singularity.Workflow.Execution.ObanBackend do
  @moduledoc """
  Oban execution backend - executes steps via Oban background jobs.

  This backend integrates with Oban to execute workflow steps as background jobs,
  enabling distributed execution, retries, and scheduling.
  """

  require Logger

  @behaviour Singularity.Workflow.Execution.Backend

  @doc """
  Execute a step function via Oban background job.

  This is asynchronous - it queues the job and returns immediately.
  The workflow execution will wait for the job to complete.
  """
  @spec execute(function(), any(), map(), map()) :: {:ok, any()} | {:error, term()}
  def execute(step_fn, input, config, context) do
    if Code.ensure_loaded?(Oban) do
      # Extract configuration
      queue = config[:queue] || :default
      timeout = config[:timeout] || 300_000
      resources = config[:resources] || []

      # Create job arguments
      job_args = %{
        step_function: encode_function(step_fn),
        input: input,
        workflow_run_id: context[:workflow_run_id],
        step_slug: context[:step_slug],
        task_index: context[:task_index],
        resources: resources,
        timeout: timeout
      }

      # Determine Oban job module based on queue/resources
      job_module = get_job_module(resources)

      Logger.debug("ObanBackend: Queuing job",
        job_module: job_module,
        queue: queue,
        resources: resources
      )

      # Insert job into Oban
      case Oban.insert(job_module.create(job_args)) do
        {:ok, job} ->
          job_id = Map.get(job, :id)

          Logger.info("ObanBackend: Job queued successfully",
            job_id: job_id,
            queue: queue
          )

          # Return job ID for tracking
          {:ok, %{job_id: job_id, queue: queue, status: :queued}}

        {:error, reason} ->
          Logger.error("ObanBackend: Failed to queue job", reason: inspect(reason))
          {:error, {:oban_insert_failed, reason}}
      end
    else
      Logger.error("ObanBackend: Oban not available")
      {:error, :oban_not_available}
    end
  end

  @doc """
  Wait for an Oban job to complete and return its result.
  """
  @spec await_job(String.t(), keyword()) :: {:ok, any()} | {:error, term()}
  def await_job(job_id, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 300_000)
    poll_interval = Keyword.get(opts, :poll_interval, 1_000)

    Logger.debug("ObanBackend: Waiting for job completion",
      job_id: job_id,
      timeout: timeout
    )

    # Poll for job completion
    case poll_job_completion(job_id, timeout, poll_interval) do
      {:completed, result} ->
        Logger.debug("ObanBackend: Job completed successfully", job_id: job_id)
        {:ok, result}

      {:failed, reason} ->
        Logger.warning("ObanBackend: Job failed", job_id: job_id, reason: inspect(reason))
        {:error, reason}

      {:timeout} ->
        Logger.error("ObanBackend: Job wait timeout", job_id: job_id, timeout: timeout)
        {:error, :job_timeout}
    end
  end

  # Poll for job completion using exponential backoff
  defp poll_job_completion(job_id, timeout, poll_interval) do
    Logger.debug("ObanBackend: Starting job polling",
      job_id: job_id,
      timeout: timeout,
      poll_interval: poll_interval
    )

    start_time = System.monotonic_time(:millisecond)
    do_poll(job_id, timeout, poll_interval, start_time)
  end

  defp do_poll(job_id, timeout, poll_interval, start_time) do
    elapsed = System.monotonic_time(:millisecond) - start_time

    if elapsed > timeout do
      {:timeout}
    else
      case check_job_status(job_id) do
        {:completed, result} ->
          {:completed, result}

        {:failed, reason} ->
          {:failed, reason}

        :running ->
          # Sleep for poll_interval before checking again
          Process.sleep(poll_interval)
          do_poll(job_id, timeout, poll_interval, start_time)

        {:error, reason} ->
          Logger.error("ObanBackend: Error checking job status",
            job_id: job_id,
            reason: inspect(reason)
          )

          {:failed, reason}
      end
    end
  end

  # Check job status in Oban database
  defp check_job_status(job_id) do
    Logger.debug("ObanBackend: Checking job status", job_id: job_id)

    if Code.ensure_loaded?(Oban) and Code.ensure_loaded?(Oban.Job) do
      # Query Oban jobs table for status
      try do
        import Ecto.Query

        # Get the Oban repo from application config
        oban_config = Application.get_env(:singularity, Oban, [])
        repo = Keyword.get(oban_config, :repo)

        if repo && function_exported?(repo, :one, 1) do
          query =
            from(j in "oban_jobs",
              where: j.id == ^job_id,
              select: %{
                state: j.state,
                errors: j.errors,
                # Oban stores results in meta field or custom field
                meta: j.meta
              }
            )

          case repo.one(query) do
            nil ->
              {:error, :job_not_found}

            %{state: "completed", meta: meta} ->
              result = Map.get(meta, "result", %{})
              {:completed, result}

            %{state: "cancelled", errors: errors} ->
              {:failed, {:cancelled, errors}}

            %{state: "discarded", errors: errors} ->
              {:failed, {:discarded, errors}}

            %{state: state} when state in ["available", "scheduled", "executing", "retryable"] ->
              :running

            %{state: other} ->
              Logger.warning("ObanBackend: Unknown Oban job state", state: other)
              :running
          end
        else
          Logger.error("ObanBackend: Oban repo not configured or unavailable")
          {:error, :oban_repo_unavailable}
        end
      rescue
        e ->
          Logger.error("ObanBackend: Exception checking job status",
            job_id: job_id,
            error: inspect(e)
          )

          {:error, {:exception, Exception.message(e)}}
      end
    else
      Logger.error("ObanBackend: Oban not loaded, cannot check job status")
      {:error, :oban_not_loaded}
    end
  end

  # Encode function for storage (simplified - in practice would need proper serialization)
  defp encode_function(fun) when is_function(fun) do
    # This is a placeholder - proper function serialization would be complex
    # In practice, you'd store module/function/arity and reconstruct
    inspect(fun)
  end

  # Determine job module based on resources
  defp get_job_module(resources) do
    if Keyword.get(resources, :gpu, false) do
      Singularity.Workflow.Jobs.GpuStepJob
    else
      Singularity.Workflow.Jobs.StepJob
    end
  end
end
