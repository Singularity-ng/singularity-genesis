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
    unless Code.ensure_loaded?(Oban) do
      Logger.error("ObanBackend: Oban not available")
      {:error, :oban_not_available}
    else
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
      case Oban.insert(job_module.new(job_args), queue: queue) do
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

  # Poll for job completion
  defp poll_job_completion(job_id, timeout, poll_interval) do
    start_time = System.monotonic_time(:millisecond)

    Stream.iterate(:continue, fn _ ->
      elapsed = System.monotonic_time(:millisecond) - start_time

      if elapsed > timeout do
        :timeout
      else
        case check_job_status(job_id) do
          {:completed, result} -> {:completed, result}
          {:failed, reason} -> {:failed, reason}
          :running -> :continue
        end
      end
    end)
    |> Enum.find(fn
      {:completed, _} -> true
      {:failed, _} -> true
      :timeout -> true
      :continue -> false
    end)
    |> case do
      {:completed, result} -> {:completed, result}
      {:failed, reason} -> {:failed, reason}
      :timeout -> {:timeout}
      :continue ->
        # Should not reach here, but fallback
        {:timeout}
    end
  end

  # Check job status in database
  defp check_job_status(job_id) do
    # This would need to be implemented based on how job results are stored
    # For now, return a placeholder
    :running
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