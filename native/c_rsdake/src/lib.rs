use hashcom_rs::{HashCommitmentScheme, SHA256Commitment};
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

#[rustler::nif]
fn commit_gen(s: Vec<i64>, r: Vec<i64>) -> Vec<u8> {
    // Move the randomness into a u8 array
    let mut r_arr = [0u8; 4];
    for i in 0..4 {
        r_arr[i] = r[i].try_into().expect("Integer casting sheisse exceptions");
    }

    // Commit string s and randomness r.
    let party = SHA256Commitment::new(&s, &r_arr);
    party.commit().expect("Commitment failed")    
}

#[rustler::nif]
fn commit_vrfy(s: Vec<i64>, r: Vec<i64>, c: Vec<i64>) -> bool {
    // Move the randomness into a u8 array
    let mut r_arr = [0u8; 4];
    for i in 0..4 {
        r_arr[i] = r[i].try_into().expect("Integer casting sheisse exceptions");
    }

    // Move the commitment into a u8 array
    let mut commit_arr = [0u8; 32];
    for i in 0..32 {
        commit_arr[i] = c[i] as u8;
    }

    // Commit string s and randomness r.
    let party = SHA256Commitment::new(&s, &r_arr);
    party.verify(&commit_arr, &s, &r_arr).expect("Commitment verification failed")
}

rustler::init!("Elixir.LAP2.Crypto.KeyExchange.CRSDAKE", [
    prf_gen,
    prf_eval,
    commit_gen,
    commit_vrfy
]);
