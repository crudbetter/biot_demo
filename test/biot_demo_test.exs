defmodule Biot.DemoTest do
  use ExUnit.Case
  doctest Biot.Demo

  test "greets the world" do
    assert Biot.Demo.hello() == :world
  end
end
