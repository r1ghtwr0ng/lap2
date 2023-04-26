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
fn commit_gen(s: Vec<u8>, r: Vec<u8>) -> Vec<u8> {
    // Move the randomness into a u8 array
    let r_arr = vec_to_arr(r);

    // Commit string s and randomness r.
    let party = SHA256Commitment::new(&s, &r_arr);
    party.commit().expect("Commitment failed")    
}

#[rustler::nif]
fn commit_vrfy(s: Vec<u8>, r: Vec<u8>, c: Vec<u8>) -> bool {
    // Move the randomness into a u8 array
    let r_arr = vec_to_arr(r);

    // Commit string s and randomness r.
    let party = SHA256Commitment::new(&s, &r_arr);
    party.verify(&c, &s, &r_arr).expect("Commitment verification failed")
}

// Convert a vector of u8 to an array of u8
fn vec_to_arr(inp_vec: Vec<u8>) -> [u8; 4] {
    let mut arr = [0u8; 4];
    for i in 0..4 {
        arr[i] = inp_vec[i].try_into().expect("Integer casting sheisse exceptions");
    }
    arr
}

rustler::init!("Elixir.LAP2.Crypto.KeyExchange.CRSDAKE", [
    prf_gen,
    prf_eval,
    commit_gen,
    commit_vrfy
]);
