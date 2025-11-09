defmodule SingularityGenesisTest do
  use ExUnit.Case
  doctest Singularity.Genesis

  test "version returns 0.1.0" do
    assert Singularity.Genesis.version() == "0.1.0"
  end
end
