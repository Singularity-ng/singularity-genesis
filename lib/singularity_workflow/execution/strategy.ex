defmodule Singularity.Workflow.Execution.Strategy do
  @moduledoc """
  Execution strategy for workflow steps.

  Provides different execution modes:
  - :sync - Execute synchronously in the current process
  - :oban - Execute via Oban background job
  - :distributed - Execute via distributed job system

  ## Usage

      # Synchronous execution (default)
      Strategy.execute(step_fn, input, %{execution: :sync})

      # Oban background execution
      Strategy.execute(step_fn, input, %{execution: :oban, queue: :gpu_jobs})

      # Distributed execution
      Strategy.execute(step_fn, input, %{execution: :distributed, resources: [gpu: true]})
  """

  require Logger
  alias Singularity.Workflow.Execution.{DirectBackend, ObanBackend}

  @type execution_config :: %{
    execution: :sync | :oban | :distributed,
    resources: keyword(),
    queue: atom() | nil,
    timeout: integer() | nil
  }

  @doc """
  Execute a step function using the specified execution strategy.
  """
  @spec execute(function(), any(), execution_config(), map()) :: {:ok, any()} | {:error, term()}
  def execute(step_fn, input, config, context \\ %{}) do
    case config.execution do
      :sync -> DirectBackend.execute(step_fn, input, config, context)
      :oban -> ObanBackend.execute(step_fn, input, config, context)
      :distributed -> DistributedBackend.execute(step_fn, input, config, context)
      other -> {:error, {:unsupported_execution_mode, other}}
    end
  end

  @doc """
  Check if an execution mode is available.
  """
  @spec available?(:sync | :oban | :distributed) :: boolean()
  def available?(:sync), do: true
  def available?(:oban), do: Code.ensure_loaded?(Oban)
  def available?(:distributed), do: false  # TODO: implement distributed backend
end