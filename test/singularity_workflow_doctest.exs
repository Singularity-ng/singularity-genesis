defmodule Singularity.WorkflowDoctestTest do
  use ExUnit.Case, async: true

  # Test documentation examples in main module
  doctest Singularity.Workflow

  # Test documentation examples in Executor module
  # Note: These doctests require database setup, so they might need async: false
  # doctest Singularity.Workflow.Executor

  # Test documentation examples in DAG modules
  # doctest Singularity.Workflow.DAG.WorkflowDefinition
end
