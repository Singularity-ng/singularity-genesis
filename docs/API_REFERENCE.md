# Singularity.Workflow API Reference

Complete API documentation for the Singularity.Workflow library.

---

## Table of Contents

1. [Workflow Execution](#workflow-execution)
2. [Workflow Lifecycle Management](#workflow-lifecycle-management)
3. [Real-Time Messaging](#real-time-messaging)
4. [Goal-Driven Orchestration (HTDAG)](#goal-driven-orchestration-htdag)
5. [Dynamic Workflow Creation](#dynamic-workflow-creation)
6. [Execution Strategies](#execution-strategies)

---

## Workflow Execution

Execute workflows defined as Elixir modules with automatic dependency resolution and parallel execution.

### `Executor.execute/3` or `Executor.execute/4`

**What it does:** Executes a workflow module with given input, managing task dependencies, parallel execution, and state persistence.

**What it solves:** Manual task coordination, dependency tracking, and retry logic. You define WHAT tasks to run and their dependencies; the executor handles HOW and WHEN.

```elixir
@spec Singularity.Workflow.Executor.execute(
  workflow_module :: module(),
  input :: map(),
  repo :: module(),
  opts :: keyword()
) :: {:ok, result :: any(), run_id :: String.t()} | {:error, reason :: term()}
```

**Example:**
```elixir
defmodule MyWorkflow do
  def __workflow_steps__ do
    [
      {:fetch, &__MODULE__.fetch/1, depends_on: []},
      {:process, &__MODULE__.process/1, depends_on: [:fetch]},
      {:save, &__MODULE__.save/1, depends_on: [:process]}
    ]
  end

  def fetch(input), do: {:ok, %{data: "..."}}
  def process(input), do: {:ok, %{result: "..."}}
  def save(input), do: {:ok, %{saved: true}}
end

{:ok, result, run_id} = Singularity.Workflow.Executor.execute(
  MyWorkflow,
  %{user_id: 123},
  MyApp.Repo
)
```

**Options:**
- `:timeout` - Maximum execution time in milliseconds (default: 300000)

---

## Workflow Lifecycle Management

Control running workflows programmatically during execution.

### `get_run_status/2`

**What it does:** Retrieves current status of a workflow execution.

**What it solves:** Real-time monitoring and progress tracking without polling the database manually.

```elixir
@spec Singularity.Workflow.get_run_status(
  run_id :: String.t(),
  repo :: module()
) :: {:ok, :completed | :failed | :in_progress, details :: term()} | {:error, :not_found}
```

**Example:**
```elixir
{:ok, :in_progress, %{total_steps: 5, completed_steps: 2, percentage: 40.0}} =
  Singularity.Workflow.get_run_status(run_id, MyApp.Repo)
```

---

### `list_workflow_runs/2`

**What it does:** Query workflow runs with filtering and pagination.

**What it solves:** Dashboard creation, monitoring interfaces, and operational visibility without writing custom queries.

```elixir
@spec Singularity.Workflow.list_workflow_runs(
  repo :: module(),
  filters :: keyword()
) :: {:ok, [WorkflowRun.t()]} | {:error, term()}
```

**Filters:**
- `:status` - "started", "completed", or "failed"
- `:workflow_slug` - Filter by workflow module name
- `:limit` - Maximum results (default: 100)
- `:offset` - Pagination offset (default: 0)
- `:order_by` - Tuple like `{:desc, :inserted_at}`

**Example:**
```elixir
# List all running workflows
{:ok, runs} = Singularity.Workflow.list_workflow_runs(
  MyApp.Repo,
  status: "started",
  limit: 20
)

# List failed workflows for specific module
{:ok, failed} = Singularity.Workflow.list_workflow_runs(
  MyApp.Repo,
  status: "failed",
  workflow_slug: "MyApp.Workflows.ProcessOrder"
)
```

---

### `cancel_workflow_run/3`

**What it does:** Cancels a running workflow, stopping pending tasks and marking the run as failed.

**What it solves:** User-initiated cancellation, timeout handling, and resource cleanup without manual database updates.

```elixir
@spec Singularity.Workflow.cancel_workflow_run(
  run_id :: String.t(),
  repo :: module(),
  opts :: keyword()
) :: :ok | {:error, term()}
```

**Options:**
- `:reason` - Cancellation reason (default: "User requested cancellation")
- `:force` - Force cancel even if already completed (default: false)

**Example:**
```elixir
:ok = Singularity.Workflow.cancel_workflow_run(
  run_id,
  MyApp.Repo,
  reason: "Timeout exceeded"
)
```

---

### `pause_workflow_run/2`

**What it does:** Pauses workflow execution, preventing new tasks from starting while allowing currently running tasks to complete.

**What it solves:** Temporary suspension for maintenance windows, rate limiting, or manual intervention scenarios.

```elixir
@spec Singularity.Workflow.pause_workflow_run(
  run_id :: String.t(),
  repo :: module()
) :: :ok | {:error, term()}
```

**Example:**
```elixir
# Pause for maintenance
:ok = Singularity.Workflow.pause_workflow_run(run_id, MyApp.Repo)

# Perform maintenance...

# Resume
:ok = Singularity.Workflow.resume_workflow_run(run_id, MyApp.Repo)
```

---

### `resume_workflow_run/2`

**What it does:** Resumes a paused workflow, allowing queued tasks to continue execution.

**What it solves:** Workflow continuation after maintenance or manual review without restarting from scratch.

```elixir
@spec Singularity.Workflow.resume_workflow_run(
  run_id :: String.t(),
  repo :: module()
) :: :ok | {:error, term()}
```

---

### `retry_failed_workflow/3`

**What it does:** Creates a new workflow execution from a failed run, optionally skipping completed steps.

**What it solves:** Transient failure recovery and partial re-execution without losing previous progress.

```elixir
@spec Singularity.Workflow.retry_failed_workflow(
  run_id :: String.t(),
  repo :: module(),
  opts :: keyword()
) :: {:ok, new_run_id :: String.t()} | {:error, term()}
```

**Options:**
- `:skip_completed` - Skip previously completed steps (default: true)
- `:reset_all` - Restart entire workflow from beginning (default: false)

**Example:**
```elixir
# Retry from point of failure
{:ok, new_run_id} = Singularity.Workflow.retry_failed_workflow(
  failed_run_id,
  MyApp.Repo
)

# Restart completely
{:ok, new_run_id} = Singularity.Workflow.retry_failed_workflow(
  failed_run_id,
  MyApp.Repo,
  reset_all: true
)
```

---

## Real-Time Messaging

PostgreSQL NOTIFY-based messaging for event-driven communication between system components.

### `send_with_notify/3`

**What it does:** Sends a message to a channel and triggers PostgreSQL NOTIFY for real-time delivery.

**What it solves:** Instant event propagation without polling, enabling reactive architectures and real-time UIs.

```elixir
@spec Singularity.Workflow.send_with_notify(
  channel :: String.t(),
  message :: map(),
  repo :: module()
) :: {:ok, message_id :: String.t()} | {:error, term()}
```

**Example:**
```elixir
{:ok, message_id} = Singularity.Workflow.send_with_notify(
  "workflow_events",
  %{
    type: "task_completed",
    workflow_id: "wf_123",
    task_id: "task_456",
    duration_ms: 1500
  },
  MyApp.Repo
)
```

---

### `listen/2`

**What it does:** Subscribes to a PostgreSQL NOTIFY channel for real-time message delivery.

**What it solves:** Event-driven architectures, real-time dashboards, and inter-service communication without external message brokers.

```elixir
@spec Singularity.Workflow.listen(
  channel :: String.t(),
  repo :: module()
) :: {:ok, pid()} | {:error, term()}
```

**Example:**
```elixir
{:ok, listener_pid} = Singularity.Workflow.listen("workflow_events", MyApp.Repo)

receive do
  {:notification, ^listener_pid, channel, message_id} ->
    IO.puts("Received message on #{channel}: #{message_id}")
end
```

---

### `unlisten/2`

**What it does:** Stops listening to a channel and cleans up the listener process.

**What it solves:** Resource cleanup and graceful shutdown of event listeners.

```elixir
@spec Singularity.Workflow.unlisten(
  listener_pid :: pid(),
  repo :: module()
) :: :ok | {:error, term()}
```

---

### `notify_only/3`

**What it does:** Sends a PostgreSQL NOTIFY without persisting to pgmq (fire-and-forget).

**What it solves:** Ephemeral notifications where message persistence isn't needed (e.g., UI updates).

```elixir
@spec Singularity.Workflow.notify_only(
  channel :: String.t(),
  payload :: String.t(),
  repo :: module()
) :: :ok | {:error, term()}
```

---

## Goal-Driven Orchestration (HTDAG)

Hierarchical Task Directed Acyclic Graph for AI/LLM-powered workflow generation.

### Why HTDAG Exists

**Problem:** AI systems need to break down high-level goals into executable task graphs dynamically. Traditional workflow systems require predefined steps, making them unsuitable for agent-based architectures.

**Solution:** HTDAG provides goal decomposition → task graph generation → workflow execution in a single pipeline, perfect for LLM-powered agents that plan their own work.

### `Orchestrator.execute_goal/5`

**What it does:** Takes a natural language goal, decomposes it into tasks via a decomposer function, creates a workflow, and executes it.

**What it solves:** The gap between high-level intentions and executable workflows. Enables AI agents to autonomously plan and execute complex multi-step tasks.

```elixir
@spec Singularity.Workflow.Orchestrator.execute_goal(
  goal :: String.t(),
  decomposer :: (String.t() -> {:ok, [task_map()]} | {:error, term()}),
  step_functions :: %{String.t() => function()},
  repo :: module(),
  opts :: keyword()
) :: {:ok, result :: any()} | {:error, term()}
```

**Example:**
```elixir
# Define how to decompose goals (could use LLM)
defmodule MyApp.GoalDecomposer do
  def decompose(goal) do
    # Call LLM or use rules to break down goal
    tasks = [
      %{id: "analyze", description: "Analyze requirements", depends_on: []},
      %{id: "design", description: "Design solution", depends_on: ["analyze"]},
      %{id: "implement", description: "Implement", depends_on: ["design"]}
    ]
    {:ok, tasks}
  end
end

# Define task implementations
step_functions = %{
  "analyze" => fn input -> {:ok, %{requirements: "..."}} end,
  "design" => fn input -> {:ok, %{architecture: "..."}} end,
  "implement" => fn input -> {:ok, %{code: "..."}} end
}

# Execute goal
{:ok, result} = Singularity.Workflow.Orchestrator.execute_goal(
  "Build user authentication system",
  &MyApp.GoalDecomposer.decompose/1,
  step_functions,
  MyApp.Repo
)
```

**Use Cases:**
- AI agents that plan their own execution
- LLM-powered task automation
- Dynamic workflow generation from natural language
- Autonomous systems that adapt workflows based on context

---

### `Orchestrator.decompose_goal/3`

**What it does:** Decomposes a goal into a hierarchical task graph without executing it.

**What it solves:** Separation of planning from execution, allowing preview/approval of task graphs before execution.

```elixir
@spec Singularity.Workflow.Orchestrator.decompose_goal(
  goal :: String.t(),
  decomposer :: function(),
  repo :: module()
) :: {:ok, task_graph :: map()} | {:error, term()}
```

**Example:**
```elixir
{:ok, task_graph} = Singularity.Workflow.Orchestrator.decompose_goal(
  "Deploy microservice to production",
  &MyApp.GoalDecomposer.decompose/1,
  MyApp.Repo
)

# task_graph contains:
# %{
#   tasks: [
#     %{id: "task1", description: "...", depends_on: []},
#     %{id: "task2", description: "...", depends_on: ["task1"]}
#   ],
#   id: "htdag_123",
#   decomposed_at: ~U[2025-11-09 ...]
# }
```

---

### `WorkflowComposer.compose_from_goal/4`

**What it does:** High-level convenience wrapper combining decomposition and execution.

**What it solves:** Single-function API for goal → execution without managing intermediate steps.

```elixir
@spec Singularity.Workflow.WorkflowComposer.compose_from_goal(
  goal :: String.t(),
  decomposer :: function(),
  step_functions :: map(),
  repo :: module()
) :: {:ok, result :: any()} | {:error, term()}
```

---

## Dynamic Workflow Creation

Runtime workflow generation for AI/LLM systems that don't know task structure ahead of time.

### `FlowBuilder.create_flow/2`

**What it does:** Creates a new dynamic workflow definition in the database.

**What it solves:** Workflow creation when structure is determined at runtime (e.g., generated by AI).

```elixir
@spec Singularity.Workflow.FlowBuilder.create_flow(
  name :: String.t(),
  repo :: module()
) :: {:ok, workflow_id :: String.t()} | {:error, term()}
```

**Example:**
```elixir
{:ok, workflow_id} = Singularity.Workflow.FlowBuilder.create_flow(
  "ai_generated_workflow",
  MyApp.Repo
)
```

---

### `FlowBuilder.add_step/4`

**What it does:** Adds a step to a dynamic workflow with dependencies.

**What it solves:** Incremental workflow construction as tasks are discovered/generated.

```elixir
@spec Singularity.Workflow.FlowBuilder.add_step(
  workflow_id :: String.t(),
  step_name :: String.t(),
  depends_on :: [String.t()],
  repo :: module()
) :: {:ok, step :: map()} | {:error, term()}
```

**Example:**
```elixir
# Build workflow incrementally
{:ok, _} = FlowBuilder.add_step(workflow_id, "step1", [], MyApp.Repo)
{:ok, _} = FlowBuilder.add_step(workflow_id, "step2", ["step1"], MyApp.Repo)
{:ok, _} = FlowBuilder.add_step(workflow_id, "step3", ["step2"], MyApp.Repo)

# Execute with step function map
step_functions = %{
  "step1" => fn input -> {:ok, %{data: "..."}} end,
  "step2" => fn input -> {:ok, %{processed: "..."}} end,
  "step3" => fn input -> {:ok, %{saved: true}} end
}

{:ok, result} = Singularity.Workflow.Executor.execute_dynamic(
  workflow_id,
  %{user_id: 123},
  step_functions,
  MyApp.Repo
)
```

---

## Execution Strategies

Control WHERE and HOW workflow tasks execute.

### Local Execution (`:local`)

**What it does:** Executes tasks in the current process sequentially or in parallel based on dependencies.

**What it solves:** Simple workflows that don't need distributed coordination or can run entirely on one node.

```elixir
def __workflow_steps__ do
  [
    {:step1, &__MODULE__.step1/1, depends_on: [], execution: :local},
    {:step2, &__MODULE__.step2/1, depends_on: [:step1], execution: :local}
  ]
end
```

**Use when:**
- Single-node deployments
- Fast-running tasks (<30 seconds)
- No resource-specific requirements

---

### Distributed Execution (`:distributed`)

**What it does:** Distributes tasks across multiple worker nodes via PostgreSQL message queuing.

**What it solves:** Horizontal scaling, resource allocation (GPU/CPU queues), and workload distribution without manual coordination.

```elixir
def __workflow_steps__ do
  [
    {:analyze, &__MODULE__.analyze/1,
     depends_on: [],
     execution: :distributed,
     queue: :cpu_workers},

    {:train_model, &__MODULE__.train/1,
     depends_on: [:analyze],
     execution: :distributed,
     queue: :gpu_workers,
     resources: [gpu: true]}
  ]
end
```

**Use when:**
- Multi-node deployments
- Long-running tasks
- Resource-specific tasks (GPU/high-memory)
- Need for fault tolerance across nodes

**Architecture:**
- Tasks are enqueued to PostgreSQL via pgmq
- Workers poll queues and claim tasks
- PostgreSQL provides coordination (no leader election needed)
- Automatic retry and fault tolerance

---

## Summary

### Core Capabilities

| Category | APIs | Solves |
|----------|------|--------|
| **Workflow Execution** | `Executor.execute/3` | Task orchestration, dependency management, parallel execution |
| **Lifecycle Control** | `cancel/pause/resume/retry/list` | Operational control, monitoring, failure recovery |
| **Messaging** | `send_with_notify/listen/unlisten` | Real-time communication, event-driven architectures |
| **HTDAG** | `Orchestrator.execute_goal` | AI/LLM goal → task graph → execution |
| **Dynamic Workflows** | `FlowBuilder.create_flow/add_step` | Runtime workflow generation |
| **Execution Strategies** | `:local` / `:distributed` | Local vs distributed execution |

### Key Design Principles

1. **PostgreSQL-Centric:** All coordination via database (no external brokers)
2. **Simple API:** Complex distributed systems with simple function calls
3. **AI-Ready:** HTDAG enables autonomous agent workflows
4. **Production-Grade:** Lifecycle management, monitoring, fault tolerance built-in

---

## Phoenix Integration

Phoenix LiveView and Channels can use Singularity.Workflow messaging directly - **no Phoenix.PubSub needed**.

### Phoenix LiveView Integration

**What it solves:** Real-time UI updates for workflow progress without polling or separate pub/sub infrastructure.

```elixir
defmodule MyAppWeb.WorkflowLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    # Start listening to workflow events
    {:ok, listener_pid} = Singularity.Workflow.listen("workflow_events", MyApp.Repo)

    {:ok,
     socket
     |> assign(:listener_pid, listener_pid)
     |> assign(:workflows, [])}
  end

  def handle_info({:notification, _pid, "workflow_events", message_id}, socket) do
    # Fetch message details and update UI
    workflow_updated = fetch_workflow_by_message(message_id)

    {:noreply,
     socket
     |> update(:workflows, fn workflows ->
       update_workflow_list(workflows, workflow_updated)
     end)}
  end

  def terminate(_reason, socket) do
    # Cleanup listener
    Singularity.Workflow.unlisten(socket.assigns.listener_pid, MyApp.Repo)
    :ok
  end
end
```

### Phoenix Channels Integration

```elixir
defmodule MyAppWeb.WorkflowChannel do
  use MyAppWeb, :channel

  def join("workflow:lobby", _payload, socket) do
    # Subscribe to workflow messages
    {:ok, listener_pid} = Singularity.Workflow.listen("workflow_events", MyApp.Repo)
    {:ok, assign(socket, :listener_pid, listener_pid)}
  end

  def handle_info({:notification, _pid, channel, message_id}, socket) do
    # Forward to connected clients
    push(socket, "workflow_update", %{
      channel: channel,
      message_id: message_id,
      timestamp: DateTime.utc_now()
    })

    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    Singularity.Workflow.unlisten(socket.assigns.listener_pid, MyApp.Repo)
    :ok
  end
end
```

### Broadcasting Workflow Events to Phoenix

```elixir
# In your workflow step
def process_data(input) do
  result = do_processing(input)

  # Broadcast to all connected LiveViews/Channels
  Singularity.Workflow.send_with_notify(
    "workflow_events",
    %{
      type: "processing_complete",
      workflow_id: input.workflow_id,
      result: result
    },
    MyApp.Repo
  )

  {:ok, result}
end
```

### Advantages Over Phoenix.PubSub

| Feature | Singularity.Workflow | Phoenix.PubSub |
|---------|----------------------|----------------|
| **Persistence** | Messages stored in PostgreSQL | Ephemeral (memory only) |
| **Multi-node** | PostgreSQL handles distribution | Requires node clustering |
| **Message History** | Queryable via pgmq | Not available |
| **Reliability** | ACID guarantees | Best-effort delivery |
| **Setup** | Uses existing database | Separate infrastructure |
| **Workflow Integration** | Native | Requires manual bridging |

### When to Use Each

**Use Singularity.Workflow Messaging:**
- Workflow status updates
- Critical notifications that need persistence
- Cross-service communication
- Multi-datacenter deployments
- When message history is needed

**Use Phoenix.PubSub:**
- Presence tracking
- Temporary UI state sync
- High-frequency ephemeral updates
- When already using Phoenix PubSub for other features

**Use Both Together:**
```elixir
# Critical workflow events → PostgreSQL NOTIFY
Singularity.Workflow.send_with_notify("workflow_critical", event, repo)

# Ephemeral UI updates → Phoenix.PubSub
Phoenix.PubSub.broadcast(MyApp.PubSub, "ui:updates", {:cursor_moved, data})
```
