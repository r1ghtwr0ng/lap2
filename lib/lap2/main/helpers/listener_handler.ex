defmodule LAP2.Main.Helpers.ListenerHandler do
  @moduledoc """
  Generates encoded JSON responses for listener processes.
  """

  alias LAP2.Main.Master

  @doc """
  Send a JSON query/response to the listener.
  """
  @spec deliver(String.t(), String.t(), binary, list(non_neg_integer), atom) :: :ok | :error
  def deliver(stream_id, type, data, query_ids, master_name) do
    # TODO send data to listener
    %{
      type: type,
      query_ids: query_ids,
      data: data
    }
    |> Jason.encode!()
    |> Master.deliver(stream_id, master_name)
  end

  @doc """
  Send a JSON notification to the listener.
  """
  @spec broadcast(binary, atom) :: :ok | :error
  def broadcast(data, _master_name) do
    # TODO broadcast to all listeners (currently on STDOUT, do TCP later)
    IO.inspect(data, label: "[BROADCAST]")
  end
end
