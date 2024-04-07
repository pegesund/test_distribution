defmodule FeederTest do
  use ExUnit.Case
  doctest Feeder

  test "greets the world" do
    assert Feeder.hello() == :world
  end
end
