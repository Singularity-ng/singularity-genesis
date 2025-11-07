import Config

# Runtime production configuration using environment variables.
# This file is executed during runtime, not at compile time.

if config_env() == :prod do
  # Database configuration from environment
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  db_ssl =
    case System.get_env("DB_SSL") do
      "true" -> true
      "false" -> false
      nil -> true
      _ -> true
    end

  config :singularity_workflow, Singularity.Workflow.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    queue_target: 5000,
    queue_interval: 1000,
    ssl: db_ssl

  # PGMQ configuration
  config :singularity_workflow, :pgmq,
    host: System.get_env("PGMQ_HOST") || "localhost",
    port: String.to_integer(System.get_env("PGMQ_PORT") || "5432"),
    database: System.get_env("PGMQ_DATABASE") || "singularity_workflow_prod",
    username: System.get_env("PGMQ_USERNAME") || "postgres",
    password: System.get_env("PGMQ_PASSWORD") || raise("PGMQ_PASSWORD is required in production"),
    pool_size: String.to_integer(System.get_env("PGMQ_POOL_SIZE") || "10"),
    timeout: String.to_integer(System.get_env("PGMQ_TIMEOUT") || "30000")

  # Logger configuration
  log_level = System.get_env("LOG_LEVEL") || "info"

  config :logger,
    level: String.to_existing_atom(log_level),
    backends: [:console],
    format: "$time $metadata[$level] $message\n",
    metadata: [:request_id, :workflow_id, :task_id]

  # Secret key base for any session/token signing
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :singularity_workflow, :secret_key_base, secret_key_base

  # Orchestrator runtime configuration
  config :singularity_workflow, :orchestrator,
    max_parallel: String.to_integer(System.get_env("ORCHESTRATOR_MAX_PARALLEL") || "20"),
    timeout: String.to_integer(System.get_env("ORCHESTRATOR_TIMEOUT") || "300000"),
    retry_attempts: String.to_integer(System.get_env("ORCHESTRATOR_RETRY_ATTEMPTS") || "3")
end
