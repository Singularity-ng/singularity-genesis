defmodule Singularity.Workflow.Jobs.StepJob do
  @moduledoc """
  Oban job for executing workflow steps in background.

  This job module integrates workflow step execution with Oban's job
  processing system, enabling:
  - Background execution
  - Automatic retries on failure
  - Scheduling and prioritization
  - Queue-based load distribution

  ## Configuration

  The job accepts the following arguments:

  - `step_function` - Encoded function to execute (MFA tuple)
  - `input` - Input data for the step
  - `workflow_run_id` - Parent workflow run ID
  - `step_slug` - Step identifier
  - `task_index` - Task index within step (for parallel tasks)
  - `resources` - Resource requirements (cpu, memory, etc.)
  - `timeout` - Execution timeout in milliseconds

  ## AI Navigation Metadata

  ### Module Identity (JSON)

  ```json
  {
    "module": "Singularity.Workflow.Jobs.StepJob",
    "purpose": "Oban job for background workflow step execution",
    "role": "worker",
    "layer": "infrastructure",
    "features": ["background_processing", "retry_logic", "resource_management"]
  }
  ```

  ### Anti-Patterns

  - L DO NOT execute long-running tasks (> 5 minutes) without chunking
  - L DO NOT store large results in job metadata (use external storage)
  -  DO implement proper timeout handling
  -  DO log execution metrics for observability
  -  DO handle errors gracefully with detailed context
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 3,
    priority: 1,
    tags: ["workflow", "step"]

  require Logger

  alias Singularity.Workflow.Execution.DirectBackend

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    start_time = System.monotonic_time(:millisecond)

    Logger.info("StepJob: Starting workflow step execution",
      workflow_run_id: args["workflow_run_id"],
      step_slug: args["step_slug"],
      task_index: args["task_index"]
    )

    # Decode the step function
    step_fn = decode_function(args["step_function"])
    input = args["input"]
    timeout = args["timeout"] || 300_000

    # Execute the step with timeout
    result =
      try do
        Task.async(fn ->
          DirectBackend.execute(step_fn, input, %{}, %{})
        end)
        |> Task.await(timeout)
      catch
        :exit, {:timeout, _} ->
          Logger.error("StepJob: Execution timeout",
            workflow_run_id: args["workflow_run_id"],
            step_slug: args["step_slug"],
            timeout: timeout
          )

          {:error, :execution_timeout}

        :exit, reason ->
          Logger.error("StepJob: Execution crashed",
            workflow_run_id: args["workflow_run_id"],
            step_slug: args["step_slug"],
            reason: inspect(reason)
          )

          {:error, {:execution_crash, reason}}
      end

    duration = System.monotonic_time(:millisecond) - start_time

    case result do
      {:ok, output} ->
        Logger.info("StepJob: Completed successfully",
          workflow_run_id: args["workflow_run_id"],
          step_slug: args["step_slug"],
          duration_ms: duration
        )

        # Store result in job metadata for retrieval
        {:ok, %{result: output, duration_ms: duration}}

      {:error, reason} ->
        Logger.error("StepJob: Failed",
          workflow_run_id: args["workflow_run_id"],
          step_slug: args["step_slug"],
          reason: inspect(reason),
          duration_ms: duration
        )

        {:error, reason}
    end
  end

  # Decode function from stored representation.
  #
  # Format:
  # - Functions are stored as `{module, function, arity}` tuple for named functions
  # - Anonymous functions cannot be serialized (limitation of BEAM)
  #
  # Future Enhancement:
  # - Lua scripts
  # - Serialized Elixir code
  # - Reference to pre-registered functions
  defp decode_function(%{"module" => module, "function" => function, "arity" => arity})
       when is_binary(module) and is_binary(function) and is_integer(arity) do
    module_atom = String.to_existing_atom("Elixir.#{module}")
    function_atom = String.to_existing_atom(function)

    if function_exported?(module_atom, function_atom, arity) do
      fn input -> apply(module_atom, function_atom, [input]) end
    else
      Logger.error("StepJob: Function not found",
        module: module,
        function: function,
        arity: arity
      )

      fn _input -> {:error, :function_not_found} end
    end
  rescue
    ArgumentError ->
      Logger.error("StepJob: Invalid function reference", module: module, function: function)
      fn _input -> {:error, :invalid_function_reference} end
  end

  defp decode_function(other) do
    Logger.warning("StepJob: Cannot decode function", value: inspect(other))
    fn _input -> {:error, :cannot_decode_function} end
  end

  # Create normalized job arguments (helper for calling code)
  # Oban.Worker's use macro provides new/1, we just need to normalize args
  defp normalize_args(args) when is_list(args) or is_map(args) do
    %{
      "step_function" => get_arg(args, :step_function),
      "input" => get_arg(args, :input),
      "workflow_run_id" => get_arg(args, :workflow_run_id),
      "step_slug" => get_arg(args, :step_slug),
      "task_index" => get_arg(args, :task_index),
      "resources" => get_arg(args, :resources) || [],
      "timeout" => get_arg(args, :timeout) || 300_000
    }
  end

  defp get_arg(args, key) when is_map(args), do: args[key] || args[to_string(key)]
  defp get_arg(args, key) when is_list(args), do: Keyword.get(args, key)

  @doc """
  Create a new StepJob with normalized arguments.

  This function wraps the auto-generated new/1 from Oban.Worker.
  """
  def create(args) when is_list(args) or is_map(args) do
    args
    |> normalize_args()
    |> new()
  end
end
