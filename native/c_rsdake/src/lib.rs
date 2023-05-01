mod utils;
mod crypto;
use rsa::RsaPrivateKey;
use rsa::pss::{BlindedSigningKey, Signature};
use rsa::sha2::{Sha256, Digest};
use rsa::signature::{Keypair, RandomizedSigner, SignatureEncoding, Verifier};
use curve25519_dalek::ristretto::RistrettoPoint;
use curve25519_dalek::scalar::Scalar;
use hashcom_rs::{HashCommitmentScheme, SHA256Commitment};
use cmac::{Cmac, Mac};
use aes::Aes256;
use rand_core::OsRng;
use crypto::{rs_vrfy, rs_sign};
use utils::*;

#[rustler::nif]
fn prf_gen(n: usize) -> Vec<u8> {
    // Generate random bytes
    (0..n/8).map(|_| rand::random::<u8>()).collect()
}

#[rustler::nif]
fn prf_eval(key: Vec<u8>, data: Vec<u8>) -> Vec<u8> {
    // Accepts 256-bit key
    let mut cmac = Cmac::<Aes256>::new_from_slice(&key).unwrap();
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
    let bits = 2048;
    let mut rng = rand::thread_rng();
    let private_key = RsaPrivateKey::new(&mut rng, bits).expect("Failed to generate signing key");
    let signing_key = BlindedSigningKey::<Sha256>::new(private_key);
    let verif_key = signing_key.verifying_key();
    // Encode and return keys
    (encode_sk_pkcs1(signing_key), encode_vk_pkcs1(verif_key))
}

#[rustler::nif]
fn standard_signature_sign(sk: Vec<u8>, message: Vec<u8>, rng: Vec<u8>) -> Vec<u8> {
    // Decode the signing key
    let signing_key: BlindedSigningKey<Sha256> = decode_sk_pkcs1(sk);
    // Hash message
    let mut hash = Sha256::new();
    hash.update(message);
    let digest: [u8; 32] = vec_to_arr(hash.finalize().to_vec());
    let mut rng = seed_rng(rng);
    // Sign message
    let signature = signing_key.sign_with_rng(&mut rng, &digest);
    signature.to_bytes().to_vec()
}

#[rustler::nif]
fn standard_signature_vrfy(signature: Vec<u8>, vk: Vec<u8>, message: Vec<u8>) -> bool {
    // Decode the verification key and signature
    let verif_key = utils::decode_vk_pkcs1(vk);
    let signature = Signature::try_from(&signature[..]).expect("Failed to decode signature");
    // SHA256 hash message
    let mut hash = Sha256::new();
    hash.update(message);
    let digest: [u8; 32] = vec_to_arr(hash.finalize().to_vec());
    // Verify signature
    verif_key.verify(&digest, &signature).is_ok()
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

rustler::init!("Elixir.LAP2.Crypto.Constructions.CryptoNifs", [
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
