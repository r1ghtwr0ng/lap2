use cmac::{Cmac, Mac};
use aes::Aes128;

#[rustler::nif]
fn prf_gen(k: usize) -> Vec<u8> {
    (0..k/8).map(|_| rand::random::<u8>()).collect()
}

#[rustler::nif]
fn prf_eval(key: Vec<u8>, data: Vec<u8>) -> Vec<u8> {
    let mut cmac = Cmac::<Aes128>::new_from_slice(&key).unwrap();
    cmac.update(&data);
    let result = cmac.finalize().into_bytes();
    result.to_vec()
}

rustler::init!("Elixir.LAP2.Crypto.KeyExchange.CRSDAKE", [
    prf_gen,
    prf_eval
]);
