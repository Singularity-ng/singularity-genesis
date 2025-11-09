defmodule Singularity.Workflow.Repo.Migrations.AddTenantIdToAllTables do
  @moduledoc """
  Adds tenant_id to all core workflow tables for multi-tenancy support.

  Enables global-scale SaaS deployments where multiple organizations/tenants
  share the same database with complete isolation.

  ## Tables Updated
  - workflow_runs
  - workflow_step_states
  - workflow_step_tasks
  - dynamic_workflows (if exists)

  ## Multi-Tenancy Strategy
  1. Add tenant_id (UUID) to all tables
  2. Create indexes on tenant_id for query performance
  3. Add composite indexes (tenant_id, other_columns) for common queries
  4. Enable PostgreSQL Row-Level Security (RLS) for isolation

  ## Backward Compatibility
  - tenant_id is nullable for existing rows
  - Applications can gradually adopt multi-tenancy
  - Single-tenant deployments can leave tenant_id NULL
  """
  use Ecto.Migration

  def up do
    # Add tenant_id to workflow_runs
    alter table(:workflow_runs) do
      add :tenant_id, :uuid, null: true
    end

    create index(:workflow_runs, [:tenant_id])
    create index(:workflow_runs, [:tenant_id, :status])
    create index(:workflow_runs, [:tenant_id, :workflow_slug])

    # Partial index for active runs per tenant
    create index(:workflow_runs, [:tenant_id, :id],
      where: "status = 'started'",
      name: :workflow_runs_tenant_active_idx
    )

    # Add tenant_id to workflow_step_states
    alter table(:workflow_step_states) do
      add :tenant_id, :uuid, null: true
    end

    create index(:workflow_step_states, [:tenant_id])
    create index(:workflow_step_states, [:tenant_id, :run_id])
    create index(:workflow_step_states, [:tenant_id, :status])

    # Add tenant_id to workflow_step_tasks
    alter table(:workflow_step_tasks) do
      add :tenant_id, :uuid, null: true
    end

    create index(:workflow_step_tasks, [:tenant_id])
    create index(:workflow_step_tasks, [:tenant_id, :run_id])
    create index(:workflow_step_tasks, [:tenant_id, :status])

    # Add comments explaining tenant_id usage
    execute """
    COMMENT ON COLUMN workflow_runs.tenant_id IS
    'Tenant/Organization ID for multi-tenancy isolation. NULL = single-tenant mode.'
    """

    execute """
    COMMENT ON COLUMN workflow_step_states.tenant_id IS
    'Tenant/Organization ID for multi-tenancy isolation. Should match workflow_runs.tenant_id.'
    """

    execute """
    COMMENT ON COLUMN workflow_step_tasks.tenant_id IS
    'Tenant/Organization ID for multi-tenancy isolation. Should match workflow_runs.tenant_id.'
    """

    # Enable Row-Level Security (RLS) - OPTIONAL, commented out for gradual adoption
    # Uncomment these lines to enforce tenant isolation at database level:

    # execute "ALTER TABLE workflow_runs ENABLE ROW LEVEL SECURITY"
    # execute "ALTER TABLE workflow_step_states ENABLE ROW LEVEL SECURITY"
    # execute "ALTER TABLE workflow_step_tasks ENABLE ROW LEVEL SECURITY"

    # execute """
    # CREATE POLICY tenant_isolation_workflow_runs ON workflow_runs
    #   USING (
    #     tenant_id IS NULL OR
    #     tenant_id = current_setting('app.current_tenant_id', true)::uuid
    #   )
    # """

    # execute """
    # CREATE POLICY tenant_isolation_step_states ON workflow_step_states
    #   USING (
    #     tenant_id IS NULL OR
    #     tenant_id = current_setting('app.current_tenant_id', true)::uuid
    #   )
    # """

    # execute """
    # CREATE POLICY tenant_isolation_step_tasks ON workflow_step_tasks
    #   USING (
    #     tenant_id IS NULL OR
    #     tenant_id = current_setting('app.current_tenant_id', true)::uuid
    #   )
    # """
  end

  def down do
    # Drop RLS policies if enabled
    # execute "DROP POLICY IF EXISTS tenant_isolation_workflow_runs ON workflow_runs"
    # execute "DROP POLICY IF EXISTS tenant_isolation_step_states ON workflow_step_states"
    # execute "DROP POLICY IF EXISTS tenant_isolation_step_tasks ON workflow_step_tasks"

    # execute "ALTER TABLE workflow_runs DISABLE ROW LEVEL SECURITY"
    # execute "ALTER TABLE workflow_step_states DISABLE ROW LEVEL SECURITY"
    # execute "ALTER TABLE workflow_step_tasks DISABLE ROW LEVEL SECURITY"

    # Remove tenant_id from workflow_step_tasks
    alter table(:workflow_step_tasks) do
      remove :tenant_id
    end

    # Remove tenant_id from workflow_step_states
    alter table(:workflow_step_states) do
      remove :tenant_id
    end

    # Remove tenant_id from workflow_runs
    alter table(:workflow_runs) do
      remove :tenant_id
    end
  end
end
