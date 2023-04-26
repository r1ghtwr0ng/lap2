defmodule LAP2.Crypto.KeyExchange.CRSDAKE do
  use Rustler, otp_app: :lap2, crate: "c_rsdake"

  # When your NIF is loaded, it will override this function.
  @spec add(any, any) :: any
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end
