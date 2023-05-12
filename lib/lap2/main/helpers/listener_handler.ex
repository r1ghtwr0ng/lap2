defmodule LAP2.Main.Helpers.ListenerHandler do
  @moduledoc """
  Generates encoded JSON responses for listener processes.
  """

  require Logger
  alias LAP2.Main.Master

  @doc """
  Send a JSON query/response to the listener.
  """
  @spec deliver(String.t(), String.t(), binary, list(non_neg_integer), atom) :: :ok | :error
  def deliver(stream_id, type, data, query_ids, master_name) do
    # TODO send data to listener
    cmd = %{
      type: type,
      query_ids: query_ids,
      data: data
    }
    |> Jason.encode!()
    case Master.get_service_target(stream_id, master_name) do
      {:ok, :stdout} -> IO.inspect(cmd, label: "[STDOUT]")
      {:ok, {:tcp, addr}} -> IO.inspect(cmd, label: "[TCP] #{inspect addr}") # TODO
      {:ok, {:native, funct, name}} -> funct.(cmd, master_name, name)
      {:error, _} -> Logger.error("Invalid stream ID: #{inspect stream_id}")
    end
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
