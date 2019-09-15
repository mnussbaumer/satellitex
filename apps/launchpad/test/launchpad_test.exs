defmodule LaunchpadTest do
  use ExUnit.Case
  doctest Launchpad

  test "greets the world" do
    assert Launchpad.hello() == :world
  end
end
