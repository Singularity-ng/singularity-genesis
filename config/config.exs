import Config

config :singularity_evolution,
  evolution: [
    enabled: true,
    auto_evolve: false,
    evolution_interval_hours: 24,
    population_size: 10,
    survivors: 3,
    mutation_rate: 0.3
  ],
  llm: [
    default_provider: :claude,
    rate_limit_rpm: 50,
    claude: [
      api_key: System.get_env("ANTHROPIC_API_KEY"),
      model: "claude-sonnet-4-5-20250929",
      max_tokens: 4096
    ],
    openai: [
      api_key: System.get_env("OPENAI_API_KEY"),
      model: "gpt-4-turbo",
      max_tokens: 4096
    ],
    local: [
      endpoint: "http://localhost:11434",
      model: "codellama:latest"
    ]
  ],
  pattern_cache: [
    max_size: 10_000,
    eviction_policy: :lru,
    persist_to_db: true,
    fitness_threshold: 0.75
  ]
