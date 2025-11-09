defmodule Singularity.Evolution do
  @moduledoc """
  Singularity Evolution - Hot-reloadable adaptive planner with evolutionary learning.

  An adaptive planning and evolution system for self-improving agent workflows.
  Sits on top of Singularity.Workflow to generate and optimize task DAGs.

  ## Architecture

  - **AdaptivePlanner** - Converts goals into HT-DAG task graphs using learned patterns or LLM
  - **EvolutionEngine** - Evaluates, selects, and breeds planner variants
  - **HotReloadManager** - Live code reloading without downtime
  - **PatternCache** - ETS-based learning from execution history
  - **LLM Clients** - Integration with Claude, OpenAI, and local models

  ## Core Principles

  1. ONE RUNTIME - Never modify singularity_workflow, only emit task graphs
  2. HOT RELOAD - Planner logic reloads live, workflows continue uninterrupted
  3. EVOLUTIONARY MEMORY - Every DAG run tracked with fitness in lineage
  4. MEASURABLE FITNESS - Success, speed, cost, determinism scored per generation
  5. SAFE MUTATION - Planner mutates policies, not execution semantics
  6. DETERMINISTIC REPLAY - Use Lineage.replay/2 for exact reproduction

  ## Usage

      # Simple planning with learned patterns
      {:ok, task_graph} = Singularity.Evolution.AdaptivePlanner.plan(
        "Build authentication system",
        %{resources: %{workers: 8}}
      )

      # Execute and learn automatically
      {:ok, result} = Singularity.Evolution.AdaptivePlanner.execute_and_learn(
        "Build authentication system",
        repo,
        learn: true
      )

      # Trigger evolution cycle
      {:ok, evolution} = Singularity.Evolution.EvolutionEngine.trigger_evolution(
        population_size: 10,
        survivors: 3,
        mutation_rate: 0.3
      )
  """

  @doc """
  Returns the version of singularity_evolution.
  """
  def version, do: "0.1.0"
end
