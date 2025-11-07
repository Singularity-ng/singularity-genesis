defmodule Singularity.Workflow.Execution.Backend do
  @moduledoc """
  Behaviour for workflow execution backends.

  Execution backends handle the actual execution of workflow steps using
  different strategies (synchronous, background jobs, distributed, etc.).
  """

  @doc """
  Execute a step function with the given configuration and context.

  Args:
    - step_fn: The function to execute
    - input: The input data for the step
    - config: Execution configuration (timeout, resources, etc.)
    - context: Execution context (workflow_run_id, step_slug, etc.)

  Returns:
    - {:ok, result} on success
    - {:error, reason} on failure
  """
  @callback execute(function(), any(), map(), map()) :: {:ok, any()} | {:error, term()}
end
