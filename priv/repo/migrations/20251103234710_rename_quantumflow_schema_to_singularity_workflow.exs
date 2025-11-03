defmodule Singularity.Workflow.Repo.Migrations.RenameQuantumflowSchemaToSingularityWorkflow do
  @moduledoc """
  Renames the PostgreSQL schema from QuantumFlow to singularity_workflow.

  This migration provides a safe upgrade path for existing databases that were
  created with the old QuantumFlow schema name.

  ## What This Does

  - Checks if the QuantumFlow schema exists
  - If it exists, renames it to singularity_workflow
  - If it doesn't exist, does nothing (assumes fresh install with new schema name)

  ## For Fresh Installs

  If you're installing on a fresh database, this migration will do nothing since
  the QuantumFlow schema never existed. The singularity_workflow schema will be
  created by the earlier migration (20251025150001_create_pgmq_queue_functions.exs).

  ## For Existing Databases

  If you have an existing database with the QuantumFlow schema, this migration
  will rename it to singularity_workflow, preserving all functions and data.
  """
  use Ecto.Migration

  def up do
    # Check if QuantumFlow schema exists and rename it
    execute("""
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'QuantumFlow'
      ) THEN
        ALTER SCHEMA "QuantumFlow" RENAME TO singularity_workflow;
        RAISE NOTICE 'Renamed schema QuantumFlow to singularity_workflow';
      ELSE
        RAISE NOTICE 'Schema QuantumFlow does not exist, skipping rename';
      END IF;
    END $$;
    """)
  end

  def down do
    # Rename back to QuantumFlow for rollback
    execute("""
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'singularity_workflow'
      ) THEN
        ALTER SCHEMA singularity_workflow RENAME TO "QuantumFlow";
        RAISE NOTICE 'Renamed schema singularity_workflow back to QuantumFlow';
      ELSE
        RAISE NOTICE 'Schema singularity_workflow does not exist, skipping rename';
      END IF;
    END $$;
    """)
  end
end
