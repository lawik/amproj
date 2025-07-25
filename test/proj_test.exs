defmodule ProjTest do
  use ExUnit.Case
  doctest Proj

  test "greets the world" do
    assert Proj.hello() == :world
  end
end
