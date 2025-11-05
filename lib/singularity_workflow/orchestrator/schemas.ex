defmodule Singularity.Workflow.Orchestrator.Schemas do
  @moduledoc """
  Backward compatibility aliases for workflow schemas.

  **DEPRECATED**: Use `SingularityWorkflowSchemas` directly instead.

  This module provides aliases to the new `SingularityWorkflowSchemas` package
  for backward compatibility. All new code should reference the schemas directly
  from the `SingularityWorkflowSchemas` module.

  ## Migration Guide

  Replace:
  ```elixir
  alias Singularity.Workflow.Orchestrator.Schemas.Workflow
  ```

  With:
  ```elixir
  alias SingularityWorkflowSchemas.Workflow
  ```
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      alias SingularityWorkflowSchemas.TaskGraph
      alias SingularityWorkflowSchemas.Workflow
      alias SingularityWorkflowSchemas.Execution
      alias SingularityWorkflowSchemas.TaskExecution
      alias SingularityWorkflowSchemas.Event
      alias SingularityWorkflowSchemas.PerformanceMetric
      alias SingularityWorkflowSchemas.LearningPattern
    end
  end

  # Re-export nested modules for backward compatibility
  defmodule TaskGraph do
    @moduledoc false
    defdelegate changeset(task_graph, attrs), to: SingularityWorkflowSchemas.TaskGraph
  end

  defmodule Workflow do
    @moduledoc false
    defdelegate workflow_changeset(workflow, attrs), to: SingularityWorkflowSchemas.Workflow
  end

  defmodule Execution do
    @moduledoc false
    defdelegate execution_changeset(execution, attrs), to: SingularityWorkflowSchemas.Execution
  end

  defmodule TaskExecution do
    @moduledoc false
    defdelegate task_execution_changeset(task_execution, attrs),
      to: SingularityWorkflowSchemas.TaskExecution
  end

  defmodule Event do
    @moduledoc false
    defdelegate event_changeset(event, attrs), to: SingularityWorkflowSchemas.Event
  end

  defmodule PerformanceMetric do
    @moduledoc false
    defdelegate performance_metric_changeset(metric, attrs),
      to: SingularityWorkflowSchemas.PerformanceMetric
  end

  defmodule LearningPattern do
    @moduledoc false
    defdelegate learning_pattern_changeset(pattern, attrs),
      to: SingularityWorkflowSchemas.LearningPattern
  end
end
