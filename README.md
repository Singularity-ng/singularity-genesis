# Singularity Evolution

Hot-reloadable adaptive planner with evolutionary learning for self-evolving agent systems.

## Overview

Singularity Evolution is an adaptive planning and evolutionary improvement system that sits on top of [Singularity Workflow](https://github.com/Singularity-ng/singularity-workflows) to automatically optimize how task DAGs are generated and executed.

**Key Features:**

- 🧠 **Adaptive Planning** - Goals → Task DAGs using learned patterns or LLM
- 🔄 **Evolutionary Learning** - Continuously improves planner variants via fitness-driven evolution
- 🔥 **Hot Reload** - Live code updates without stopping running workflows
- 📊 **Measurable Fitness** - Success × Speed × Cost × Determinism scoring
- 🎯 **Deterministic Replay** - Verify and improve reproducibility

## Architecture

```
┌─────────────────────────────────────┐
│  singularity_evolution (THIS)      │
│  ├─ AdaptivePlanner                │ ← LLM/Pattern-based planning
│  ├─ EvolutionEngine                │ ← Fitness, mutation, selection
│  └─ HotReloadManager               │ ← Live code updates
└──────────────┬──────────────────────┘
               │ emits task graphs
               ↓
┌─────────────────────────────────────┐
│  singularity_workflow (SPINE)      │ ← Stable runtime
│  ├─ Orchestrator (HT-DAG)          │
│  ├─ DAG Execution                  │
│  └─ Lineage Tracking               │
└─────────────────────────────────────┘
```

## Core Components

### AdaptivePlanner

Converts goals into task DAGs using:
- **Pattern Cache** - Fast lookup of successful patterns (ETS)
- **LLM Integration** - Claude, OpenAI, or local models for novel goals
- **Automatic Learning** - Updates patterns based on execution outcomes

```elixir
{:ok, task_graph} = AdaptivePlanner.plan(
  "Build authentication system",
  %{resources: %{workers: 8}}
)
```

### EvolutionEngine

Improves planner variants through:
- **Fitness Evaluation** - Score variants on benchmark suite
- **Tournament Selection** - Pick best performers
- **Genetic Operators** - Mutation and crossover for breeding
- **Hot Reload** - Load improved variants without downtime

```elixir
{:ok, result} = EvolutionEngine.trigger_evolution(
  population_size: 10,
  survivors: 3,
  mutation_rate: 0.3
)
```

### HotReloadManager

Live code updates via:
- **Module Generation** - Create new planner from variant parameters
- **Safe Reload** - Compile, verify, load without affecting running workflows
- **Rollback Support** - Return to previous version if needed
- **History Tracking** - Audit trail of all reloads

```elixir
{:ok, result} = HotReload.reload_planner(variant)
{:ok, _} = HotReload.rollback(steps: 1)
```

## Core Principles

1. **ONE RUNTIME** - Never modify singularity_workflow, only emit task graphs
2. **HOT RELOAD** - Planner logic reloads live, workflows continue uninterrupted
3. **EVOLUTIONARY MEMORY** - Every DAG run stored with fitness in lineage
4. **MEASURABLE FITNESS** - Success, speed, cost, determinism tracked per generation
5. **SAFE MUTATION** - Planner mutates policies, not execution semantics
6. **DETERMINISTIC REPLAY** - Use Lineage.replay/2 for exact reproduction

## Fitness Scoring

Multi-dimensional fitness from execution metrics:

```
fitness = 0.5 * success_score +
          0.3 * speed_score +
          0.1 * cost_score +
          0.1 * determinism_score
```

Where:
- **Success** - 1.0 if completed, 0.0 if failed
- **Speed** - 1.0 / (duration_sec + 1)
- **Cost** - 1.0 / (task_count + 1)
- **Determinism** - 1.0 if replay matches, 0.0 otherwise

## Installation

```elixir
def deps do
  [
    {:singularity_evolution, git: "https://github.com/Singularity-ng/singularity-evolution.git"}
  ]
end
```

## Usage Examples

### Simple Planning

```elixir
# Plan with learned patterns or LLM fallback
{:ok, task_graph} = Singularity.Evolution.AdaptivePlanner.plan(
  "Build REST API for product catalog",
  %{resources: %{workers: 4}}
)
```

### Execute and Learn

```elixir
# Automatically plan, execute, and improve
{:ok, result} = Singularity.Evolution.AdaptivePlanner.execute_and_learn(
  "Build REST API for product catalog",
  MyApp.Repo,
  learn: true
)
```

### Evolutionary Improvement

```elixir
# Trigger evolution cycle
{:ok, evolution} = Singularity.Evolution.EvolutionEngine.trigger_evolution(
  population_size: 10,
  survivors: 3,
  mutation_rate: 0.3
)

IO.puts("Best fitness: #{evolution.avg_fitness}")
IO.puts("Generation: #{evolution.generation}")
```

### Hot Reload

```elixir
# Live reload improved planner
{:ok, reload} = Singularity.Evolution.HotReload.reload_planner(new_variant)

# Rollback if needed
{:ok, _} = Singularity.Evolution.HotReload.rollback()
```

## Configuration

```elixir
# config/config.exs
config :singularity_evolution,
  evolution: [
    enabled: true,
    auto_evolve: true,
    evolution_interval_hours: 24,
    population_size: 20,
    survivors: 5
  ],
  llm: [
    default_provider: :claude,
    claude: [
      api_key: System.get_env("ANTHROPIC_API_KEY"),
      model: "claude-sonnet-4-5-20250929",
      max_tokens: 4096
    ]
  ],
  pattern_cache: [
    max_size: 10_000,
    eviction_policy: :lru,
    persist_to_db: true
  ]
```

## Integration with Singularity Workflow

Singularity Evolution uses the [Lineage API](https://github.com/Singularity-ng/singularity-workflows) from Singularity Workflow:

```elixir
# Get execution history for learning
{:ok, lineage} = Singularity.Workflow.Lineage.get_lineage(run_id, repo)

# Replay workflow for determinism check
{:ok, replay_run_id} = Singularity.Workflow.Lineage.replay(lineage, step_functions, repo)

# Calculate fitness
fitness = FitnessEvaluator.calculate(lineage)
```

## Development

```bash
# Setup
mix deps.get
mix ecto.create

# Test
mix test

# Code quality
mix quality   # Runs format, credo, dialyzer, sobelow
mix test.coverage

# Docs
mix docs
```

## Testing Strategy

- **Unit Tests** - Individual functions with mocks
- **Integration Tests** - Full planning → execution → learning cycles
- **Benchmark Tests** - Evolution effectiveness on standard problems

## Roadmap

- [x] Core module scaffolding
- [ ] AdaptivePlanner implementation (Week 1-2)
- [ ] LLM client integration (Week 2-3)
- [ ] Pattern cache and learning (Week 3-4)
- [ ] EvolutionEngine implementation (Week 4-5)
- [ ] Hot reload system (Week 5-6)
- [ ] Benchmark suite and metrics (Week 6-7)
- [ ] Production hardening (Week 7-8)

## License

MIT

## References

- [Singularity Workflow](https://github.com/Singularity-ng/singularity-workflows) - DAG execution and lineage tracking
- [Evo.txt](./Evo.txt) - Complete specification document
- [Elixir Documentation](https://elixir-lang.org/docs.html)
