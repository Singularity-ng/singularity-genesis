defmodule Singularity.Workflow.Execution.Strategy do
  @moduledoc """
  Execution strategy for workflow steps.

  Provides different execution modes:
  - :sync - Execute synchronously in the current process
  - :oban - Execute via Oban background jobs for distributed execution

  ## Usage

      # Synchronous execution (default)
      Strategy.execute(step_fn, input, %{execution: :sync})

      # Oban distributed execution
      Strategy.execute(step_fn, input, %{execution: :oban, queue: :gpu_jobs})

  ## Distributed Execution

  Use `:oban` mode for distributed workflow execution. Oban provides:
  - Background job processing across multiple nodes
  - Retry logic and error handling
  - Resource-based queue routing (CPU, GPU)
  - Persistent job state
  """

  require Logger
  alias Singularity.Workflow.Execution.{DirectBackend, ObanBackend}

  @type execution_config :: %{
          execution: :sync | :oban,
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
      other -> {:error, {:unsupported_execution_mode, other}}
    end
  end

  @doc """
  Check if an execution mode is available.
  """
  @spec available?(:sync | :oban) :: boolean()
  def available?(:sync), do: true
  def available?(:oban), do: Code.ensure_loaded?(Oban)
end
