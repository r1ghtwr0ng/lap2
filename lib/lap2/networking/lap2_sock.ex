defmodule LAP2.Networking.LAP2Socket do
    use GenServer

    # Client API
    def start_link(state) when is_map(state) do
        GenServer.start_link(__MODULE__, state, name: {:global, :lap2_sock})
    end

    @doc """
    Update the GenServer state.
    """
    def update(pid, map) when is_pid(pid) do
        GenServer.call(pid, {:update, map})
    end

    @doc """
    Get the GenServer state.
    """
    def get(pid) when is_pid(pid) do
        GenServer.call(pid, :get)
    end

    # Server API
    def init(state) do
        # Open UDP socket
        case :gen_udp.open(state.udp_port, [binary: true, active: true]) do
            {:ok, udp_sock} -> {:ok, Map.merge(state, %{udp_sock: udp_sock})}
            {:error, _} -> {:stop, :udp_open_error} # TODO add logging
        end
    end

    def handle_call({:update, map}, _from, state) do
        {:reply, :ok, Map.merge(state, map)}
    end

    def handle_call(:get, _from, state) do
        {:reply, state, state}
    end

    # ---- Helper functions ----

end
