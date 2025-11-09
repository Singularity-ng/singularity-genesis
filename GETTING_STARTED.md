# Getting Started with Singularity.Workflow

> **📦 This is a library** - You add it to your Elixir application as a dependency, just like Ecto or Oban.

Singularity.Workflow is a **library package** that provides database-driven workflow orchestration for your Elixir applications. This guide walks you through adding it to your application, basic setup, and running your first workflow.

## Installation

Add `singularity_workflow` to **your application's** `mix.exs` dependencies:

```elixir
# In YOUR application's mix.exs
def deps do
  [
    {:singularity_workflow, "~> 1.0.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

**Important**: This installs the library into your application. You don't run Singularity.Workflow as a standalone service - it's code you use within your app.

## Database Setup in Your Application

Singularity.Workflow uses **your application's database** and requires PostgreSQL 12+ with the `pgmq` extension.

### 1. Your Database (if you don't have one)

```bash
# Create your application's database
createdb my_app_dev
```

### 2. Configure Your Application's Repo

Singularity.Workflow uses **your existing Ecto repo** - no separate repo needed:

```elixir
# config/config.exs in YOUR application
config :my_app, MyApp.Repo,
  database: "my_app_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :my_app,
  ecto_repos: [MyApp.Repo]
```

### 3. Install pgmq Extension

```bash
# Install pgmq extension in YOUR database
psql my_app_dev -c "CREATE EXTENSION IF NOT EXISTS pgmq"
```

### 4. Run Migrations (Optional)

The library includes migrations for workflow tables. You can copy them to your app if needed:

```bash
# Singularity.Workflow tables will be created automatically
# when you execute workflows using your repo
```

The library manages these tables:
- `workflow_runs` - Tracks workflow execution instances
- `workflow_step_states` - State for each step in a run
- `workflow_step_tasks` - Individual tasks for map steps
- `workflow_step_dependencies` - Dependency edges in the DAG
- pgmq queue tables - For task coordination

## Your First Workflow

### 1. Define a Workflow in Your Application

Create a workflow module in your application that uses the library:

```elixir
# In YOUR application: lib/my_app/workflows/hello_world.ex
defmodule MyApp.Workflows.HelloWorld do
  def __workflow_steps__ do
    [
      {:greet, &__MODULE__.greet/1, depends_on: []}
    ]
  end

  def greet(_input) do
    {:ok, %{"message" => "Hello, World!"}}
  end

  @impl true
  def on_complete(run_id, output, context) do
    IO.inspect(output, label: "Workflow completed")
    :ok
  end

  @impl true
  def on_failure(run_id, error, context) do
    IO.inspect(error, label: "Workflow failed")
    :ok
  end
end
```

### 2. Start the Workflow

```elixir
alias MyApp.Workflows.HelloWorld

# Start a new workflow run
{:ok, run_id} = HelloWorld.start(%{"name" => "Alice"})

# Check status
{:ok, run} = HelloWorld.status(run_id)
IO.inspect(run)
# => %Singularity.Workflow.WorkflowRun{
#   id: "...",
#   workflow_slug: "MyApp.Workflows.HelloWorld",
#   status: "started",
#   input: %{"name" => "Alice"},
#   remaining_steps: 1
# }
```

### 3. Execute Pending Tasks

The workflow engine coordinates task execution via the pgmq queue. To process tasks:

```elixir
alias Singularity.Workflow.Executor

# Poll the queue and execute pending tasks
{:ok, executed_count} = Executor.execute_pending_tasks()

# Wait for completion
:timer.sleep(1000)

# Check final status
{:ok, run} = HelloWorld.status(run_id)
IO.inspect(run.status)  # => "completed"
```

## DAG Workflows with Dependencies

Singularity.Workflow supports complex DAG workflows with parallel execution and dependency management:

```elixir
defmodule MyApp.Workflows.DataPipeline do
  @behaviour Singularity.Workflow.Executor.Workflow

  @impl true
  def definition do
    %{
      "version" => "1.0",
      "title" => "Data Processing Pipeline",
      "steps" => [
        # Extract data from two sources in parallel
        %{
          "name" => "extract_users",
          "type" => "task",
          "command" => "extract",
          "args" => %{"source" => "users"}
        },
        %{
          "name" => "extract_orders",
          "type" => "task",
          "command" => "extract",
          "args" => %{"source" => "orders"}
        },
        # Join them
        %{
          "name" => "join",
          "type" => "task",
          "command" => "merge",
          "dependencies" => ["extract_users", "extract_orders"]
        },
        # Load to warehouse
        %{
          "name" => "load",
          "type" => "task",
          "command" => "load",
          "dependencies" => ["join"]
        }
      ]
    }
  end

  @impl true
  def execute_command(_run_id, "extract", %{"source" => source}, _ctx) do
    # Simulate data extraction
    {:ok, %{"items" => 100, "source" => source}}
  end

  @impl true
  def execute_command(_run_id, "merge", input, _ctx) do
    # Merge results from previous steps
    {:ok, %{"merged_count" => 200}}
  end

  @impl true
  def execute_command(_run_id, "load", input, _ctx) do
    # Load to warehouse
    {:ok, %{"loaded" => true}}
  end

  @impl true
  def on_complete(_run_id, output, _ctx) do
    IO.puts("Pipeline completed!")
  end

  @impl true
  def on_failure(_run_id, error, _ctx) do
    IO.inspect(error, label: "Pipeline failed")
  end
end
```

## Map Steps (Parallel Iteration)

Execute the same task across multiple items:

```elixir
defmodule MyApp.Workflows.ProcessItems do
  @behaviour Singularity.Workflow.Executor.Workflow

  @impl true
  def definition do
    %{
      "version" => "1.0",
      "title" => "Process Multiple Items",
      "steps" => [
        # Map step: create a task for each item
        %{
          "name" => "process_items",
          "type" => "map",
          "command" => "process",
          "over" => "[1, 2, 3, 4, 5]"
        },
        # Wait for all to complete
        %{
          "name" => "aggregate",
          "type" => "task",
          "command" => "aggregate",
          "dependencies" => ["process_items"]
        }
      ]
    }
  end

  @impl true
  def execute_command(_run_id, "process", %{"item" => item}, _ctx) do
    {:ok, %{"processed" => item, "result" => item * 2}}
  end

  @impl true
  def execute_command(_run_id, "aggregate", input, _ctx) do
    {:ok, %{"aggregated" => true}}
  end

  @impl true
  def on_complete(_run_id, _output, _ctx), do: :ok
  def on_failure(_run_id, _error, _ctx), do: :ok
end
```

## Goal-Driven Workflows with HTDAG

Want workflows that understand **goals** instead of explicit tasks? Use HTDAG (Hierarchical Task DAG) for automatic workflow decomposition.

### Define a Goal Decomposer

```elixir
defmodule MyApp.SimpleDecomposer do
  def decompose(goal) do
    # Break goal into steps (could use rules, LLM, or both)
    tasks = [
      %{id: "analyze", description: "Analyze: #{goal}", depends_on: []},
      %{id: "plan", description: "Plan solution", depends_on: ["analyze"]},
      %{id: "execute", description: "Execute plan", depends_on: ["plan"]},
      %{id: "verify", description: "Verify result", depends_on: ["execute"]}
    ]
    {:ok, tasks}
  end
end
```

### Define Step Functions

```elixir
step_functions = %{
  "analyze" => fn input ->
    analysis = "Analysis of #{input.goal} complete"
    {:ok, %{analysis: analysis}}
  end,
  "plan" => fn input ->
    plan = "Plan based on: #{input.analysis}"
    {:ok, %{plan: plan}}
  end,
  "execute" => fn input ->
    result = "Executed: #{input.plan}"
    {:ok, %{result: result}}
  end,
  "verify" => fn input ->
    {:ok, %{verified: true, final_result: input.result}}
  end
}
```

### Execute Goal-Driven Workflow

```elixir
{:ok, result} = Singularity.Workflow.WorkflowComposer.compose_from_goal(
  "Build a user authentication system",
  &MyApp.SimpleDecomposer.decompose/1,
  step_functions,
  MyApp.Repo,
  optimization_level: :basic  # Start safe, can increase later
)

IO.inspect(result)
# => %{verified: true, final_result: "Executed: Plan..."}
```

### Optimization Levels

```elixir
# :basic - Safe, conservative optimizations
{:ok, result} = Singularity.Workflow.WorkflowComposer.compose_from_goal(
  goal,
  &decomposer/1,
  steps,
  repo,
  optimization_level: :basic
)

# :advanced - Intelligent optimizations based on historical data
{:ok, result} = Singularity.Workflow.WorkflowComposer.compose_from_goal(
  goal,
  &decomposer/1,
  steps,
  repo,
  optimization_level: :advanced,
  monitoring: true
)

# :aggressive - Maximum optimization (requires 100+ executions)
{:ok, result} = Singularity.Workflow.WorkflowComposer.compose_from_goal(
  goal,
  &decomposer/1,
  steps,
  repo,
  optimization_level: :aggressive
)
```

### Multi-Workflow Composition

Execute multiple goals in parallel:

```elixir
goals = [
  "Build authentication service",
  "Build payment service",
  "Build notification service"
]

{:ok, results} = Singularity.Workflow.WorkflowComposer.compose_multiple_workflows(
  goals,
  &MyApp.ServiceDecomposer.decompose/1,
  %{
    "auth" => auth_step_functions,
    "payment" => payment_step_functions,
    "notification" => notification_step_functions
  },
  MyApp.Repo,
  parallel: true  # Execute all three in parallel
)
```

For the complete guide, see [HTDAG_ORCHESTRATOR_GUIDE.md](docs/HTDAG_ORCHESTRATOR_GUIDE.md).

## Configuration

Singularity.Workflow respects these environment variables:

```bash
# PostgreSQL connection
DATABASE_URL=postgres://user:pass@localhost:5432/my_app

# PGMQ queue name (default: singularity_workflow_queue)
SINGULARITY_WORKFLOW_QUEUE_NAME=my_queue

# Visibility timeout for in-flight tasks (default: 300s = 5 min)
SINGULARITY_WORKFLOW_VT=300

# Max concurrent task executions (default: 10)
SINGULARITY_WORKFLOW_MAX_WORKERS=10
```

## Troubleshooting

### "pgmq extension not found"

Install the extension:

```bash
pgxn install pgmq
createdb my_app
psql my_app -c "CREATE EXTENSION IF NOT EXISTS pgmq"
```

### "Queue not found"

Ensure migrations have run:

```bash
mix ecto.status  # Check pending migrations
mix ecto.migrate  # Run all migrations
```

### Tasks hanging or not executing

Check queue health:

```elixir
alias Singularity.Workflow.Executor

# See how many tasks are pending
{:ok, count} = Executor.pending_task_count()
IO.inspect(count)

# Manually trigger task processing
Executor.execute_pending_tasks()
```

### Type errors in custom workflows

Singularity.Workflow uses Dialyzer for type checking. Run:

```bash
mix dialyzer
```

## Next Steps

- Read [ARCHITECTURE.md](docs/ARCHITECTURE.md) for internal design details
- Check [DYNAMIC_WORKFLOWS_GUIDE.md](docs/DYNAMIC_WORKFLOWS_GUIDE.md) for advanced patterns
- See [SINGULARITY_WORKFLOW_REFERENCE.md](docs/SINGULARITY_WORKFLOW_REFERENCE.md) for complete API documentation
- Review [SECURITY_AUDIT.md](docs/SECURITY_AUDIT.md) for security considerations

## Contributing

Found a bug? Have a feature request? See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT - See [LICENSE.md](LICENSE.md) for details.
