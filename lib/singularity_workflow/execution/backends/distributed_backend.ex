defmodule Singularity.Workflow.Execution.DistributedBackend do
  @moduledoc """
  Distributed execution backend - executes steps via distributed job system.

  Placeholder for future distributed execution capabilities (Kubernetes, etc.).
  """

  require Logger

  @behaviour Singularity.Workflow.Execution.Backend

  @doc """
  Execute a step function via distributed job system.

  Currently not implemented - returns an error.
  """
  @spec execute(function(), any(), map(), map()) :: {:ok, any()} | {:error, term()}
  def execute(_step_fn, _input, _config, _context) do
    Logger.warning("DistributedBackend: Distributed execution not yet implemented")
    {:error, :not_implemented}
  end
end