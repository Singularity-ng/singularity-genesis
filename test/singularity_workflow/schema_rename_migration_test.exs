defmodule Singularity.Workflow.SchemaRenameMigrationTest do
  use ExUnit.Case, async: false

  alias Singularity.Workflow.Repo

  @moduletag :migration_test

  # Load the migration module
  Code.require_file(
    "priv/repo/migrations/20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs",
    File.cwd!()
  )

  alias Singularity.Workflow.Repo.Migrations.RenameQuantumflowSchemaToSingularityWorkflow

  setup do
    # Skip tests if database is not available
    if System.get_env("SINGULARITY_WORKFLOW_SKIP_DB") == "1" do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    end

    :ok
  end

  describe "schema rename migration" do
    @tag :skip
    test "migration up creates singularity_workflow schema if QuantumFlow exists" do
      # This test is skipped by default as it requires manual database setup
      # To run: Create a test database with QuantumFlow schema and remove @tag :skip

      # Setup: Create old schema
      Ecto.Adapters.SQL.query!(Repo, "DROP SCHEMA IF EXISTS \"QuantumFlow\" CASCADE", [])
      Ecto.Adapters.SQL.query!(Repo, "DROP SCHEMA IF EXISTS singularity_workflow CASCADE", [])
      Ecto.Adapters.SQL.query!(Repo, "CREATE SCHEMA \"QuantumFlow\"", [])

      # Verify old schema exists
      result =
        Ecto.Adapters.SQL.query!(
          Repo,
          "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'QuantumFlow'",
          []
        )

      assert length(result.rows) == 1

      # Run migration up
      RenameQuantumflowSchemaToSingularityWorkflow.up()

      # Verify old schema is gone
      result =
        Ecto.Adapters.SQL.query!(
          Repo,
          "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'QuantumFlow'",
          []
        )

      assert result.rows == []

      # Verify new schema exists
      result =
        Ecto.Adapters.SQL.query!(
          Repo,
          "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'singularity_workflow'",
          []
        )

      assert length(result.rows) == 1
    end

    @tag :skip
    test "migration up is idempotent - does nothing if QuantumFlow doesn't exist" do
      # This test is skipped by default as it requires manual database setup

      # Setup: Ensure only new schema exists
      Ecto.Adapters.SQL.query!(Repo, "DROP SCHEMA IF EXISTS \"QuantumFlow\" CASCADE", [])
      Ecto.Adapters.SQL.query!(Repo, "DROP SCHEMA IF EXISTS singularity_workflow CASCADE", [])
      Ecto.Adapters.SQL.query!(Repo, "CREATE SCHEMA singularity_workflow", [])

      # Verify old schema doesn't exist
      result =
        Ecto.Adapters.SQL.query!(
          Repo,
          "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'QuantumFlow'",
          []
        )

      assert result.rows == []

      # Run migration up - should not error
      assert :ok = RenameQuantumflowSchemaToSingularityWorkflow.up()

      # Verify new schema still exists
      result =
        Ecto.Adapters.SQL.query!(
          Repo,
          "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'singularity_workflow'",
          []
        )

      assert length(result.rows) == 1
    end

    @tag :skip
    test "migration down renames schema back to QuantumFlow" do
      # This test is skipped by default as it requires manual database setup

      # Setup: Create new schema
      Ecto.Adapters.SQL.query!(Repo, "DROP SCHEMA IF EXISTS \"QuantumFlow\" CASCADE", [])
      Ecto.Adapters.SQL.query!(Repo, "DROP SCHEMA IF EXISTS singularity_workflow CASCADE", [])
      Ecto.Adapters.SQL.query!(Repo, "CREATE SCHEMA singularity_workflow", [])

      # Verify new schema exists
      result =
        Ecto.Adapters.SQL.query!(
          Repo,
          "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'singularity_workflow'",
          []
        )

      assert length(result.rows) == 1

      # Run migration down
      RenameQuantumflowSchemaToSingularityWorkflow.down()

      # Verify new schema is gone
      result =
        Ecto.Adapters.SQL.query!(
          Repo,
          "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'singularity_workflow'",
          []
        )

      assert result.rows == []

      # Verify old schema exists
      result =
        Ecto.Adapters.SQL.query!(
          Repo,
          "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'QuantumFlow'",
          []
        )

      assert length(result.rows) == 1
    end

    test "migration module is properly defined" do
      # Test that the migration module is accessible
      assert Code.ensure_loaded?(RenameQuantumflowSchemaToSingularityWorkflow)

      # Test that the module has the required functions
      assert function_exported?(RenameQuantumflowSchemaToSingularityWorkflow, :up, 0)
      assert function_exported?(RenameQuantumflowSchemaToSingularityWorkflow, :down, 0)
    end

    test "migration file exists in correct location" do
      migration_path =
        Path.join([
          File.cwd!(),
          "priv",
          "repo",
          "migrations",
          "20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs"
        ])

      assert File.exists?(migration_path), "Migration file should exist at #{migration_path}"
    end

    test "migration has proper documentation" do
      # Verify the migration file contains proper documentation
      migration_file =
        Path.join([
          File.cwd!(),
          "priv",
          "repo",
          "migrations",
          "20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs"
        ])

      content = File.read!(migration_file)

      assert content =~ "@moduledoc", "Migration should have a @moduledoc"
      assert content =~ "Renames the PostgreSQL schema"
      assert content =~ "QuantumFlow"
      assert content =~ "singularity_workflow"
      assert content =~ "safe upgrade path"
    end
  end
end
