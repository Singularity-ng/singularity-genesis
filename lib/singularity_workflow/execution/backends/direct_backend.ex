defmodule Singularity.Workflow.Execution.DirectBackend do
  @moduledoc """
  Direct execution backend - executes steps synchronously in the current process.

  This is the default execution mode that maintains backward compatibility.
  """

  require Logger

  @behaviour Singularity.Workflow.Execution.Backend

  @doc """
  Execute a step function synchronously.
  """
  @spec execute(function(), any(), map(), map()) :: {:ok, any()} | {:error, term()}
  def execute(step_fn, input, config, _context) do
    timeout = config[:timeout] || 30_000

    Logger.debug("DirectBackend: Executing step synchronously",
      timeout: timeout
    )

    # Execute with timeout using Task
    task = Task.async(fn -> step_fn.(input) end)

    case Task.yield(task, timeout) do
      {:ok, {:ok, result}} ->
        Logger.debug("DirectBackend: Step completed successfully")
        {:ok, result}

      {:ok, {:error, reason}} ->
        Logger.warning("DirectBackend: Step returned error", reason: inspect(reason))
        {:error, reason}

      nil ->
        Task.shutdown(task, :brutal_kill)
        Logger.error("DirectBackend: Step timed out", timeout: timeout)
        {:error, :timeout}

      {:exit, reason} ->
        Logger.error("DirectBackend: Step crashed", reason: inspect(reason))
        {:error, {:crashed, reason}}
    end
  end
end