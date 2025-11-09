defmodule Singularity.Workflow.Execution.DistributedBackend do
  @moduledoc """
  Distributed execution backend using Singularity.Workflow's PostgreSQL + pgmq.

  This backend enables distributed execution across multiple nodes/workers using
  the library's built-in PostgreSQL + pgmq infrastructure. Oban is used internally
  as an implementation detail and is not exposed to users.

  ## How It Works

  1. Work is enqueued to pgmq queues in PostgreSQL
  2. Multiple workers across nodes poll these queues
  3. PostgreSQL provides coordination and state management
  4. Built-in retry logic and fault tolerance via pgmq

  ## Features

  - **Multi-node execution** - Workers on any node can process tasks
  - **Resource allocation** - Queue-based routing (GPU, CPU queues)
  - **Fault tolerance** - PostgreSQL ACID guarantees + pgmq retry logic
  - **Load balancing** - Workers pull from shared queues
  - **No external dependencies** - Uses PostgreSQL only (no NATS, no external brokers)

  ## Usage

      # Distributed execution (uses pgmq internally)
      Strategy.execute(step_fn, input, %{
        execution: :distributed,
        resources: [gpu: true],
        queue: :gpu_workers
      })

  ## Architecture

  Wraps ObanBackend internally but exposes a cleaner distributed execution API.
  Users don't need to know about Oban - they just use `:distributed` mode.
  """

  require Logger

  @behaviour Singularity.Workflow.Execution.Backend

  alias Singularity.Workflow.Execution.ObanBackend

  @doc """
  Execute a step function via distributed backend (PostgreSQL + pgmq).

  Internally uses Oban for job management, but this is an implementation detail.
  Users interact with a simple distributed execution API.

  ## Parameters

  - `step_fn` - Function to execute
  - `input` - Input data
  - `config` - Execution config (resources, queue, timeout)
  - `context` - Execution context (run_id, step_slug, etc.)

  ## Returns

  - `{:ok, result}` - Execution completed successfully
  - `{:error, reason}` - Execution failed
  """
  @spec execute(function(), any(), map(), map()) :: {:ok, any()} | {:error, term()}
  def execute(step_fn, input, config, context) do
    Logger.debug("DistributedBackend: Delegating to pgmq-based execution",
      resources: config[:resources],
      queue: config[:queue]
    )

    # Delegate to ObanBackend (implementation detail)
    # Users don't need to know we use Oban internally
    ObanBackend.execute(step_fn, input, config, context)
  end

  @doc """
  Check if distributed backend is available.

  Returns true if Oban is loaded (our internal implementation).
  """
  @spec available?() :: boolean()
  def available? do
    Code.ensure_loaded?(Oban)
  end
end
