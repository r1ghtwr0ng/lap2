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
  def deliver(listener_id, type, data, query_ids, master_name) do
    # TODO send data to listener
    cmd = %{
      type: type,
      query_ids: query_ids,
      data: data
    }

    Master.get_service_target(listener_id, master_name)
    |> case do
      {:ok, listener} -> deliver_to_listener(listener, cmd)
      {:error, _} -> Logger.error("Invalid stream ID: #{inspect listener_id}")
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

  @doc """
  Deliver a JSON command to a listener.
  """
  @spec deliver_to_listener(atom | tuple, map) :: :ok | :error
  def deliver_to_listener(listener_id, cmd) do
    case listener_id do
      :stdout -> IO.inspect(cmd, label: "[STDOUT]")
      {:tcp, addr} -> IO.inspect(cmd, label: "[TCP] #{inspect addr}") # TODO
      {:native, funct, name} -> funct.(cmd, name)
      list -> Logger.error("Unknown listener type: #{inspect list}")
    end
  end
end
