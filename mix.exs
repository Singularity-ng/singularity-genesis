defmodule SingularityEvolution.MixProject do
  use Mix.Project

  def project do
    [
      app: :singularity_evolution,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Hot-reloadable adaptive planner with evolutionary learning for self-evolving agent systems",
      package: package(),
      dialyzer: [plt_add_app: :app_tree],
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Singularity.Evolution.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:singularity_workflow, git: "https://github.com/Singularity-ng/singularity-workflows.git"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.21"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},

      # Testing
      {:ex_machina, "~> 2.8", only: :test},
      {:mox, "~> 1.0", only: :test},

      # Development
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp package do
    [
      name: "singularity_evolution",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      maintainers: ["Singularity-ng"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Singularity-ng/singularity-evolution"}
    ]
  end
end
