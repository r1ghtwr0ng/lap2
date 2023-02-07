defmodule LAP2.Networking.LAP2SocketTest do
  use ExUnit.Case
  doctest Networking.LAP2Socket

  test "test" do
    assert Networking.LAP2Socket.() == :ok
  end
end