mod utils;
mod crypto;
use curve25519_dalek::ristretto::RistrettoPoint;
use curve25519_dalek::scalar::Scalar;
use ed25519_dalek::{Keypair, Signature, PublicKey, Signer, Verifier};
use hashcom_rs::{HashCommitmentScheme, SHA256Commitment};
use cmac::{Cmac, Mac};
use aes::Aes128;
use rand_core::OsRng;
use utils::{restretto_to_vec, deconstruct_keypair, reconstruct_keypair};
use crate::crypto::{rs_vrfy, rs_sign};
use crate::utils::{fixed_vec_to_arr, deconstruct_sag, reconstruct_sag, vec_to_arr, vec_to_restretto};

#[rustler::nif]
fn prf_gen(n: usize) -> Vec<u8> {
    // Generate random bytes
    (0..n/8).map(|_| rand::random::<u8>()).collect()
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
    let r_arr = fixed_vec_to_arr(r);

    // Commit string s and randomness r.
    let party = SHA256Commitment::new(&s, &r_arr);
    party.commit().expect("Commitment failed")    
}

#[rustler::nif]
fn commit_vrfy(s: Vec<u8>, r: Vec<u8>, c: Vec<u8>) -> bool {
    // Move the randomness into a u8 array
    let r_arr = fixed_vec_to_arr(r);

    // Commit string s and randomness r.
    let party = SHA256Commitment::new(&s, &r_arr);
    party.verify(&c, &s, &r_arr).expect("Commitment verification failed")
}

#[rustler::nif]
fn standard_signature_gen() -> (Vec<u8>, Vec<u8>) {
    // Generate keys
    let mut csprng = OsRng::default();
    let keypair: Keypair = Keypair::generate(&mut csprng);
    deconstruct_keypair(keypair)
}

#[rustler::nif]
fn standard_signature_sign(sk: Vec<u8>, pk: Vec<u8>, message: Vec<u8>) -> Vec<u8> {
    // Reconstruct keypair struct
    let keypair = reconstruct_keypair(sk, pk);
    // Sign message
    let signature: Signature = keypair.sign(&message);
    signature.to_bytes().to_vec()
}

#[rustler::nif]
fn standard_signature_vrfy(signature: Vec<u8>, pk: Vec<u8>, message: Vec<u8>) -> bool {
    // Reconstruct public key struct
    let pk = PublicKey::from_bytes(&pk).unwrap();
    // Reconstruct signature struct
    let signature = Signature::from_bytes(&signature).unwrap();
    // Verify signature
    pk.verify(&message, &signature).is_ok()
}

#[rustler::nif]
fn rs_nif_gen() -> (Vec<u8>, Vec<u8>) {
    let mut csprng = OsRng::default();
    let sk: Vec<u8> = Scalar::random(&mut csprng).to_bytes().to_vec();
    let pk: Vec<u8> = restretto_to_vec(RistrettoPoint::random(&mut csprng));
    (sk, pk)
}

#[rustler::nif]
fn rs_nif_sign(secret_idx: usize, sk: Vec<u8>, vec_ring: Vec<Vec<u8>>, message: Vec<u8>) -> (Vec<u8>, Vec<Vec<u8>>, Vec<Vec<u8>>) {
    // Convert the secret key to a Scalar
    let sk = Scalar::from_bytes_mod_order(vec_to_arr(sk));
    
    // Convert the ring to a Vec<RistrettoPoint>
    let mut ring = Vec::new();
    for i in 0..vec_ring.len() {
        ring.push(vec_to_restretto(vec_ring[i].clone()));
    }

    // Message conversion
    let msg = message.iter().cloned().collect();

    // Generate the signature
    let signature = rs_sign(secret_idx, sk, ring, msg);
    
    // Deconstruct the SAG struct and pass back to Elixir
    deconstruct_sag(signature)
}

#[rustler::nif]
fn rs_nif_vrfy(challenge: Vec<u8>, ring: Vec<Vec<u8>>, responses: Vec<Vec<u8>>, message: Vec<u8>) -> bool {
    // Reconstruct the SAG struct
    let sag = reconstruct_sag(challenge, ring, responses);

    // Message conversion
    let msg = message.iter().cloned().collect();
    
    // Verify the signature
    rs_vrfy(sag, msg)
}

rustler::init!("Elixir.LAP2.Crypto.KeyExchange.CryptoNifs", [
    prf_gen,
    prf_eval,
    commit_gen,
    commit_vrfy,
    rs_nif_gen,
    rs_nif_sign,
    rs_nif_vrfy,
    standard_signature_gen,
    standard_signature_sign,
    standard_signature_vrfy
]);
