defmodule Singularity.Evolution.Application do
  @moduledoc """
  Singularity.Evolution application supervisor.

  Manages:
  - Pattern cache (ETS table)
  - Evolution state (GenServer)
  - Hot reload tracking (GenServer)
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Singularity.Evolution")

    children = [
      # Pattern cache - ETS table for learned patterns
      {Singularity.Evolution.PatternCache, []},
      # Evolution engine state
      {Singularity.Evolution.EvolutionEngine.State, []},
      # Hot reload history tracking
      {Singularity.Evolution.HotReload.History, []}
    ]

    opts = [strategy: :one_for_one, name: Singularity.Evolution.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
