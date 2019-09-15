defmodule SatelliteSharedTest do
  use ExUnit.Case
  doctest SatelliteShared

  test "greets the world" do
    assert SatelliteShared.hello() == :world
  end
end
