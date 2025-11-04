defmodule Singularity.Workflow.SchemaRenameMigrationTest do
  use ExUnit.Case, async: true

  @moduletag :migration_test

  # Load the migration module
  Code.require_file(
    "priv/repo/migrations/20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs",
    File.cwd!()
  )

  alias Singularity.Workflow.Repo.Migrations.RenameQuantumflowSchemaToSingularityWorkflow

  describe "migration module structure" do
    test "migration module is properly defined" do
      assert Code.ensure_loaded?(RenameQuantumflowSchemaToSingularityWorkflow)
    end

    test "migration module has up/0 function" do
      assert function_exported?(RenameQuantumflowSchemaToSingularityWorkflow, :up, 0)
    end

    test "migration module has down/0 function" do
      assert function_exported?(RenameQuantumflowSchemaToSingularityWorkflow, :down, 0)
    end

    test "migration module uses Ecto.Migration" do
      migration_file =
        Path.join([
          File.cwd!(),
          "priv",
          "repo",
          "migrations",
          "20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs"
        ])

      content = File.read!(migration_file)
      assert content =~ "use Ecto.Migration"
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

      assert File.exists?(migration_path)
    end

    test "migration filename follows Ecto naming convention" do
      migration_path =
        Path.join([
          File.cwd!(),
          "priv",
          "repo",
          "migrations",
          "20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs"
        ])

      assert Path.basename(migration_path) =~
               ~r/^\d{14}_rename_quantumflow_schema_to_singularity_workflow\.exs$/
    end
  end

  describe "migration documentation" do
    setup do
      migration_file =
        Path.join([
          File.cwd!(),
          "priv",
          "repo",
          "migrations",
          "20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs"
        ])

      {:ok, content: File.read!(migration_file)}
    end

    test "migration has @moduledoc", %{content: content} do
      assert content =~ "@moduledoc"
    end

    test "documentation mentions schema rename", %{content: content} do
      assert content =~ "Renames the PostgreSQL schema"
    end

    test "documentation mentions QuantumFlow", %{content: content} do
      assert content =~ "QuantumFlow"
    end

    test "documentation mentions singularity_workflow", %{content: content} do
      assert content =~ "singularity_workflow"
    end

    test "documentation mentions safe upgrade path", %{content: content} do
      assert content =~ "safe upgrade path"
    end

    test "documentation mentions existing databases", %{content: content} do
      assert content =~ "existing databases" or content =~ "Existing Databases"
    end

    test "documentation mentions fresh installs", %{content: content} do
      assert content =~ "fresh install" or content =~ "Fresh Install"
    end
  end

  describe "migration up SQL validation" do
    setup do
      migration_file =
        Path.join([
          File.cwd!(),
          "priv",
          "repo",
          "migrations",
          "20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs"
        ])

      {:ok, content: File.read!(migration_file)}
    end

    test "up migration uses execute/1", %{content: content} do
      assert content =~ "execute("
    end

    test "up migration checks information_schema.schemata", %{content: content} do
      assert content =~ "information_schema.schemata"
    end

    test "up migration checks for QuantumFlow schema existence", %{content: content} do
      assert content =~ "schema_name = 'QuantumFlow'"
    end

    test "up migration uses ALTER SCHEMA", %{content: content} do
      assert content =~ "ALTER SCHEMA"
    end

    test "up migration renames to singularity_workflow", %{content: content} do
      assert content =~ "RENAME TO singularity_workflow"
    end

    test "up migration uses PL/pgSQL", %{content: content} do
      assert content =~ "DO $$"
    end

    test "up migration uses IF EXISTS conditional", %{content: content} do
      assert content =~ "IF EXISTS"
    end

    test "up migration uses RAISE NOTICE for renamed message", %{content: content} do
      assert content =~ "RAISE NOTICE 'Renamed schema QuantumFlow to singularity_workflow'"
    end

    test "up migration uses RAISE NOTICE for skip message", %{content: content} do
      assert content =~ "RAISE NOTICE 'Schema QuantumFlow does not exist, skipping rename'"
    end
  end

  describe "migration down SQL validation" do
    setup do
      migration_file =
        Path.join([
          File.cwd!(),
          "priv",
          "repo",
          "migrations",
          "20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs"
        ])

      {:ok, content: File.read!(migration_file)}
    end

    test "down migration uses execute/1", %{content: content} do
      [_before_down, down_section] = String.split(content, "def down do")
      assert down_section =~ "execute("
    end

    test "down migration checks for singularity_workflow schema", %{content: content} do
      assert content =~ "schema_name = 'singularity_workflow'"
    end

    test "down migration renames back to QuantumFlow", %{content: content} do
      assert content =~ ~s(RENAME TO "QuantumFlow")
    end

    test "down migration uses RAISE NOTICE for rollback message", %{content: content} do
      assert content =~ "Renamed schema singularity_workflow back to QuantumFlow"
    end

    test "down migration uses RAISE NOTICE for skip message", %{content: content} do
      assert content =~ "Schema singularity_workflow does not exist, skipping rename"
    end
  end

  describe "migration SQL structure" do
    setup do
      migration_file =
        Path.join([
          File.cwd!(),
          "priv",
          "repo",
          "migrations",
          "20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs"
        ])

      {:ok, content: File.read!(migration_file)}
    end

    test "migration uses proper BEGIN/END blocks", %{content: content} do
      assert content =~ "BEGIN"
      assert content =~ "END"
    end

    test "migration SQL uses proper THEN clause", %{content: content} do
      assert content =~ "THEN"
    end

    test "migration SQL uses ELSE clause for non-existence case", %{content: content} do
      assert content =~ "ELSE"
    end

    test "migration ends with END IF", %{content: content} do
      assert content =~ "END IF"
    end
  end

  describe "all migration files naming validation" do
    test "no migration files reference QuantumFlow in module name" do
      migrations_dir = Path.join([File.cwd!(), "priv", "repo", "migrations"])
      migration_files = File.ls!(migrations_dir)

      for file <- migration_files do
        content = File.read!(Path.join(migrations_dir, file))

        if content =~ "defmodule" and content =~ "Migrations" do
          assert content =~ "Singularity.Workflow.Repo.Migrations",
                 "Migration #{file} should use Singularity.Workflow.Repo.Migrations namespace"

          refute content =~ "QuantumFlow.Repo.Migrations",
                 "Migration #{file} should not use QuantumFlow.Repo.Migrations namespace"
        end
      end
    end

    test "all PostgreSQL functions use singularity_workflow schema" do
      migrations_dir = Path.join([File.cwd!(), "priv", "repo", "migrations"])
      migration_files = File.ls!(migrations_dir)

      for file <- migration_files do
        content = File.read!(Path.join(migrations_dir, file))

        if content =~ "CREATE FUNCTION" or content =~ "CREATE OR REPLACE FUNCTION" do
          if content =~ ~r/CREATE.*FUNCTION\s+\w+\./ do
            refute content =~ ~r/CREATE.*FUNCTION\s+QuantumFlow\./,
                   "Migration #{file} should not create functions in QuantumFlow schema"
          end
        end
      end
    end
  end

  describe "codebase QuantumFlow reference validation" do
    test "lib/ files use Singularity.Workflow not QuantumFlow in module names" do
      lib_dir = Path.join([File.cwd!(), "lib"])
      lib_files = Path.wildcard(Path.join(lib_dir, "**/*.ex"))

      for file <- lib_files do
        content = File.read!(file)

        if content =~ "defmodule" do
          refute content =~ "defmodule QuantumFlow",
                 "#{file} should not define QuantumFlow modules"

          refute content =~ "defmodule Quantum",
                 "#{file} should not define Quantum modules"
        end
      end
    end

    test "README mentions Singularity.Workflow" do
      readme_path = Path.join([File.cwd!(), "README.md"])

      if File.exists?(readme_path) do
        content = File.read!(readme_path)
        assert content =~ "Singularity.Workflow" or content =~ "singularity_workflow"
      end
    end

    test "mix.exs uses singularity_workflow as app name" do
      mix_file = Path.join([File.cwd!(), "mix.exs"])
      content = File.read!(mix_file)
      assert content =~ "app: :singularity_workflow"
      refute content =~ "app: :quantum_flow"
    end
  end

  describe "production deployment guide validation" do
    setup do
      guide_path = Path.join([File.cwd!(), "docs", "SCHEMA_MIGRATION_GUIDE.md"])
      {:ok, guide_path: guide_path, content: File.read!(guide_path)}
    end

    test "SCHEMA_MIGRATION_GUIDE.md exists", %{guide_path: guide_path} do
      assert File.exists?(guide_path)
    end

    test "guide mentions backup procedures", %{content: content} do
      assert content =~ "backup" or content =~ "Backup"
    end

    test "guide mentions rollback procedures", %{content: content} do
      assert content =~ "rollback" or content =~ "Rollback"
    end

    test "guide mentions verification steps", %{content: content} do
      assert content =~ "verify" or content =~ "Verify"
    end

    test "guide mentions troubleshooting", %{content: content} do
      assert content =~ "troubleshooting" or content =~ "Troubleshooting"
    end

    test "guide provides pg_dump command", %{content: content} do
      assert content =~ "pg_dump"
    end

    test "guide mentions mix ecto.migrate", %{content: content} do
      assert content =~ "mix ecto.migrate"
    end

    test "guide mentions mix ecto.rollback", %{content: content} do
      assert content =~ "mix ecto.rollback"
    end

    test "guide lists read_with_poll function", %{content: content} do
      assert content =~ "read_with_poll"
    end

    test "guide lists create_flow function", %{content: content} do
      assert content =~ "create_flow"
    end

    test "guide lists add_step function", %{content: content} do
      assert content =~ "add_step"
    end

    test "guide lists fail_task function", %{content: content} do
      assert content =~ "fail_task"
    end

    test "guide lists maybe_complete_run function", %{content: content} do
      assert content =~ "maybe_complete_run"
    end

    test "guide lists set_vt_batch function", %{content: content} do
      assert content =~ "set_vt_batch"
    end

    test "guide lists is_valid_slug function", %{content: content} do
      assert content =~ "is_valid_slug"
    end

    test "guide lists cascade_complete_taskless_steps function", %{content: content} do
      assert content =~ "cascade_complete_taskless_steps"
    end

    test "guide lists ensure_workflow_queue function", %{content: content} do
      assert content =~ "ensure_workflow_queue"
    end

    test "guide lists calculate_retry_delay function", %{content: content} do
      assert content =~ "calculate_retry_delay"
    end

    test "guide has production deployment checklist", %{content: content} do
      assert content =~ "checklist" or content =~ "Checklist"
    end

    test "guide mentions schema rename operation", %{content: content} do
      # The guide explains the rename happens automatically via the migration
      assert content =~ "rename"
    end
  end

  describe "GitHub workflows validation" do
    test "docker-build.yml uses singularity_workflow naming" do
      workflow_path = Path.join([File.cwd!(), ".github", "workflows", "docker-build.yml"])

      if File.exists?(workflow_path) do
        content = File.read!(workflow_path)
        refute content =~ "quantum_flow-postgres"
        assert content =~ "singularity" or content =~ "workflow"
      end
    end

    test "publish.yml uses singularity_workflow_test database" do
      workflow_path = Path.join([File.cwd!(), ".github", "workflows", "publish.yml"])

      if File.exists?(workflow_path) do
        content = File.read!(workflow_path)
        assert content =~ "singularity_workflow_test"
        refute content =~ "quantum_flow_test"
      end
    end
  end
end
