defmodule Singularity.Workflow.Execution.DistributedBackend do
  @moduledoc """
  Distributed execution backend for workflow steps.

  This backend will enable distributed execution across multiple nodes/workers,
  with support for:
  - Resource allocation (GPU, CPU, memory)
  - Work stealing between nodes
  - Fault tolerance and retry logic
  - Load balancing

  ## Status

  **Currently in development** - This is a production-grade stub that returns
  appropriate errors until the full distributed system is implemented.

  ## Future Implementation

  Will integrate with:
  - NATS for distributed messaging
  - Resource scheduler for GPU/CPU allocation
  - Distributed state management
  - Circuit breakers for fault tolerance

  ## AI Navigation Metadata

  ### Module Identity (JSON)

  ```json
  {
    "module": "Singularity.Workflow.Execution.DistributedBackend",
    "purpose": "Distributed execution backend for workflow steps across multiple nodes",
    "role": "backend",
    "layer": "infrastructure",
    "status": "in_development",
    "features": ["distributed_execution", "resource_allocation", "fault_tolerance"]
  }
  ```

  ### Anti-Patterns

  - ❌ DO NOT use this backend in production until fully implemented
  - ❌ DO NOT remove error returns - they prevent silent failures
  - ✅ DO implement proper resource scheduling before enabling
  - ✅ DO add distributed tracing when implementing
  - ✅ DO implement circuit breakers for fault tolerance
  """

  require Logger

  @behaviour Singularity.Workflow.Execution.Backend

  @doc """
  Execute a step function via distributed backend.

  ## Current Behavior

  Returns `{:error, :not_implemented}` with detailed logging.

  ## Future Behavior

  Will:
  1. Schedule work on appropriate node based on resources
  2. Monitor execution across nodes
  3. Handle failures with retry logic
  4. Return results from remote execution
  """
  @spec execute(function(), any(), map(), map()) :: {:error, {:not_implemented, String.t()}}
  def execute(_step_fn, _input, config, context) do
    Logger.warning(
      "DistributedBackend.execute/4 called but not yet implemented",
      config: config,
      context: context,
      recommendation: "Use :oban execution mode for distributed work"
    )

    {:error,
     {:not_implemented,
      "Distributed backend is in development. Use execution: :oban for distributed work."}}
  end

  @doc """
  Check if distributed backend is available.

  Returns `false` until implementation is complete.
  """
  @spec available?() :: false
  def available?, do: false

  @doc """
  Get list of available worker nodes.

  ## Future Implementation

  Will return list of connected nodes with their:
  - Available resources (GPU, CPU, memory)
  - Current load
  - Health status
  """
  @spec list_workers() :: {:error, :not_implemented}
  def list_workers do
    {:error, :not_implemented}
  end

  @doc """
  Schedule work on specific node or let scheduler decide.

  ## Future Implementation

  Will implement intelligent scheduling based on:
  - Resource requirements
  - Current node load
  - Data locality
  - Network topology
  """
  @spec schedule_work(any(), keyword()) :: {:error, :not_implemented}
  def schedule_work(_work_spec, _opts \\ []) do
    {:error, :not_implemented}
  end
end
