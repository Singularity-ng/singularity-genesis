defmodule Singularity.Genesis.FitnessEvaluator do
  @moduledoc """
  Fitness scoring for planner variants and task graphs.

  Calculates multi-dimensional fitness from execution metrics:
  - Success rate (binary: success or failure)
  - Speed (1.0 / (duration_sec + 1))
  - Cost efficiency (1.0 / (task_count + 1))
  - Determinism (1.0 if replay produces same result)

  ## Fitness Formula

  ```
  fitness = 0.5 * success_score +
            0.3 * speed_score +
            0.1 * cost_score +
            0.1 * determinism_score
  ```

  Range: 0.0 (worst) to 1.0 (perfect)
  """

  @doc """
  Calculate fitness score from execution metrics.

  ## Parameters

  - `lineage` - Execution lineage from Singularity.Workflow.Lineage
  - `opts` - Scoring options:
    - `:weights` - Custom weight distribution
    - `:replay_lineage` - For determinism scoring

  ## Returns

  Fitness score: 0.0 to 1.0

  ## Example

      {:ok, lineage} = Lineage.get_lineage(run_id, repo)
      fitness = calculate(lineage)
      # => 0.85
  """
  @spec calculate(lineage :: map(), opts :: keyword()) :: float()
  def calculate(lineage, opts \\ []) do
    # TODO: Implement fitness calculation
    # 1. Extract metrics from lineage
    # 2. Calculate component scores
    # 3. Apply weights
    # 4. Return aggregate fitness
    0.0
  end

  @doc """
  Calculate success score (binary).

  Returns 1.0 if completed, 0.0 if failed.
  """
  @spec success_score(lineage :: map()) :: float()
  def success_score(lineage) do
    case lineage.metrics.status do
      "completed" -> 1.0
      _ -> 0.0
    end
  end

  @doc """
  Calculate speed score based on duration.

  Faster executions score higher.
  Formula: 1.0 / (duration_sec + 1)
  """
  @spec speed_score(lineage :: map()) :: float()
  def speed_score(lineage) do
    duration_sec = lineage.metrics.duration_ms / 1000
    1.0 / (duration_sec + 1)
  end

  @doc """
  Calculate cost score based on task count.

  Fewer tasks score higher.
  Formula: 1.0 / (task_count + 1)
  """
  @spec cost_score(lineage :: map()) :: float()
  def cost_score(lineage) do
    task_count = lineage.metrics.total_tasks
    1.0 / (task_count + 1)
  end

  @doc """
  Calculate determinism score from replay comparison.

  Perfect determinism (same result) = 1.0
  Different result = 0.0
  """
  @spec determinism_score(lineage :: map(), replay_lineage :: map()) :: float()
  def determinism_score(lineage, replay_lineage) do
    if lineage.metrics == replay_lineage.metrics, do: 1.0, else: 0.0
  end
end
