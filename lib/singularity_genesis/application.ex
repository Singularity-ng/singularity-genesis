defmodule Singularity.Genesis.Application do
  @moduledoc """
  Singularity.Genesis application supervisor.

  Manages:
  - Pattern cache (ETS table)
  - Evolution state (GenServer)
  - Hot reload tracking (GenServer)
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Singularity.Genesis")

    children = [
      # Pattern cache - ETS table for learned patterns
      {Singularity.Genesis.PatternCache, []},
      # Evolution engine state
      {Singularity.Genesis.EvolutionEngine.State, []},
      # Hot reload history tracking
      {Singularity.Genesis.HotReload.History, []}
    ]

    opts = [strategy: :one_for_one, name: Singularity.Genesis.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
