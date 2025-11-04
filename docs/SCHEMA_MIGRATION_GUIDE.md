# Schema Migration Guide: QuantumFlow → singularity_workflow

This guide explains how to safely migrate existing databases from the old `QuantumFlow` PostgreSQL schema to the new `singularity_workflow` schema.

## For Fresh Installations

If you're installing Singularity.Workflow on a fresh database, you don't need to do anything special. Just run:

```bash
mix ecto.migrate
```

The system will automatically create the `singularity_workflow` schema with all functions.

## For Existing Databases (Upgrade Path)

If you have an existing database that was created with the `QuantumFlow` schema, follow these steps:

### Step 1: Backup Your Database

**IMPORTANT**: Always backup your database before running migrations.

```bash
pg_dump -Fc your_database_name > backup_before_schema_rename.dump
```

### Step 2: Run the Migration

The migration is designed to be safe and idempotent:

```bash
mix ecto.migrate
```

The migration (`20251103234710_rename_quantumflow_schema_to_singularity_workflow.exs`) will:
- Check if the `QuantumFlow` schema exists
- If it exists, rename it to `singularity_workflow`
- If it doesn't exist, do nothing (assumes fresh install)

### Step 3: Verify the Migration

After running the migration, verify that:

```sql
-- Check that the new schema exists
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'singularity_workflow';

-- Check that all functions are in the new schema
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'singularity_workflow';
```

You should see all 10 functions:
- `read_with_poll`
- `ensure_workflow_queue`
- `create_flow`
- `add_step`
- `fail_task`
- `calculate_retry_delay`
- `maybe_complete_run`
- `set_vt_batch`
- `is_valid_slug`
- `cascade_complete_taskless_steps`

### Step 4: (Optional) Rollback

If you need to rollback the migration:

```bash
mix ecto.rollback --step 1
```

This will rename the schema back from `singularity_workflow` to `QuantumFlow`.

## Migration Details

### What Gets Renamed

- **PostgreSQL Schema**: `QuantumFlow` → `singularity_workflow`
- **All Functions**: Automatically moved to the new schema
- **All Data**: Preserved (schema rename doesn't affect data)

### What Doesn't Change

- Table structures remain the same
- Data in tables is preserved
- Workflow execution logic is unchanged

### Idempotency

The migration can be run multiple times safely. If the `QuantumFlow` schema doesn't exist, the migration does nothing.

## Troubleshooting

### Error: "schema 'QuantumFlow' does not exist"

This is normal if you're on a fresh installation. The migration will skip the rename and log a notice.

### Error: "schema 'singularity_workflow' already exists"

This could happen if you manually created the schema. The migration will fail to prevent data loss. Options:

1. Drop the manually-created `singularity_workflow` schema first (if it's empty)
2. Or manually rename `QuantumFlow` to `singularity_workflow` before running migrations

### Verification Failed

If functions are missing after migration:

```sql
-- Check which schema they're in
SELECT routine_schema, routine_name 
FROM information_schema.routines 
WHERE routine_name IN ('read_with_poll', 'create_flow', 'add_step');
```

If they're still in `QuantumFlow`, the migration didn't run. Check migration status:

```bash
mix ecto.migrations
```

## Production Deployment Checklist

- [ ] Database backup completed
- [ ] Reviewed migration plan with team
- [ ] Tested migration in staging environment
- [ ] Scheduled maintenance window (if required)
- [ ] Run `mix ecto.migrate`
- [ ] Verify all functions are in `singularity_workflow` schema
- [ ] Verify application still works
- [ ] Monitor logs for any schema-related errors

## Support

If you encounter issues during migration, please open an issue on GitHub with:
- PostgreSQL version
- Output of `mix ecto.migrations`
- Any error messages
- Result of the verification queries above
