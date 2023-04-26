defmodule LAP2.Crypto.KeyExchange.CRSDAKE do
  use Rustler, otp_app: :lap2, crate: "c_rsdake"

  # When your NIF is loaded, it will override this function.
  def prf_gen(_a), do: :erlang.nif_error(:nif_not_loaded)

  def prf_eval(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end
