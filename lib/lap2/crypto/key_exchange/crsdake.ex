defmodule LAP2.Crypto.KeyExchange.CRSDAKE do
  use Rustler, otp_app: :lap2, crate: "c_rsdake"

  # When your NIF is loaded, it will override this function.
  @spec prf_gen(non_neg_integer) :: binary
  def prf_gen(_a), do: :erlang.nif_error(:nif_not_loaded)

  @spec prf_eval(binary, binary) :: binary
  def prf_eval(_a, _b), do: :erlang.nif_error(:nif_not_loaded)

  @spec commit_gen(binary, binary) :: binary
  def commit_gen(_s, _r), do: :erlang.nif_error(:nif_not_loaded)

  @spec commit_vrfy(binary, binary, binary) :: boolean
  def commit_vrfy(_s, _r, _c), do: :erlang.nif_error(:nif_not_loaded)
end
