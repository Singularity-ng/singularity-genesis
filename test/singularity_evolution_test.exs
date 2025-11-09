defmodule SingularityEvolutionTest do
  use ExUnit.Case
  doctest Singularity.Evolution

  test "version returns 0.1.0" do
    assert Singularity.Evolution.version() == "0.1.0"
  end
end
