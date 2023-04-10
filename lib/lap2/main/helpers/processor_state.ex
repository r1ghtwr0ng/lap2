defmodule LAP2.Main.Helpers.ProcessorState do
  @moduledoc """
  Helper functions for processing the share handler state.
  """

  @doc """
  Route a share to the appropriate processing stage.
  """
  @spec route_share(map, map) :: {:drop | :reassemble | :cache}
  def route_share(state, share) do
    # TODO check if the share is valid
    # TODO check if share.message_id is in the state
    # If it is, check if the share is a duplicate
    # If it is, drop it
    # If it isn't, check if there is enough shares in the ets cache for reassembly
    # If there is, reassemble the message and send it to the share handler
    # If there isn't, cache the share and return
  end
end
