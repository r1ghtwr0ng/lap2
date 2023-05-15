use curve25519_dalek::{ristretto::{RistrettoPoint, CompressedRistretto}, scalar::Scalar};
use rand_chacha::{rand_core::SeedableRng, ChaCha8Rng};
use nazgul::sag::SAG;
use rsa::sha2::Sha256;
use rsa::{RsaPrivateKey, RsaPublicKey};
use rsa::pss::{BlindedSigningKey, VerifyingKey};
use rsa::pkcs1::{EncodeRsaPrivateKey, EncodeRsaPublicKey, DecodeRsaPrivateKey, DecodeRsaPublicKey};

// Deconstruct the SAG struct into a tuple of (challenge, ring, responses)
pub fn deconstruct_sag(signature: SAG) -> (Vec<u8>, Vec<Vec<u8>>, Vec<Vec<u8>>) {
    let sag_chal = signature.challenge.as_bytes().to_vec();
    let mut sag_ring = Vec::new();
    let mut sag_resp = Vec::new();

    for i in 0..signature.responses.len(){
        sag_resp.push(signature.responses[i].as_bytes().to_vec());
    }

    for i in 0..signature.ring.len(){
        sag_ring.push(restretto_to_vec(signature.ring[i]));
    }

    (sag_chal, sag_ring, sag_resp)
}

// Reconstruct the SAG struct from a tuple of (challenge, ring, responses)
pub fn reconstruct_sag(c: Vec<u8>, r: Vec<Vec<u8>>, s: Vec<Vec<u8>>) -> SAG {
    // Covert the challenge to a Scalar
    let challenge = Scalar::from_bytes_mod_order(vec_to_arr(c));

    // Convert the rings to RistrettoPoints
    let mut ring = Vec::new();
    for i in 0..r.len() {
        ring.push(vec_to_restretto(r[i].clone()));
    }

    let mut responses = Vec::new();
    for i in 0..s.len(){
        let s_arr = s[i].clone().try_into().unwrap();
        responses.push(Scalar::from_bytes_mod_order(s_arr));
    }

    SAG {
        challenge: challenge,
        ring: ring,
        responses: responses
    }
}

// Convert a vector of u8 to an array of [u8; N]
pub fn vec_to_arr<T, const N: usize>(v: Vec<T>) -> [T; N] {
    v.try_into()
        .unwrap_or_else(|v: Vec<T>| panic!("Expected a Vec of length {} but it was {}", N, v.len()))
}

// Convert a RistrettoPoint to a vector of u8 (32 bytes)
pub fn restretto_to_vec(point: RistrettoPoint) -> Vec<u8> {
    point.compress().to_bytes().to_vec()
}

// Convert a vector of u8 (32 bytes) to a RistrettoPoint
pub fn vec_to_restretto(v: Vec<u8>) -> RistrettoPoint {
    let bytes: [u8; 32] = vec_to_arr(v.clone());
    let new = CompressedRistretto::from_slice(&bytes);
    new.decompress().unwrap()
}

// Encode an RSA private key to a vector of u8
pub fn encode_sk_pkcs1(sk: BlindedSigningKey<Sha256>) -> Vec<u8> {
    sk.to_pkcs1_der()
        .expect("Unable to encode RSA private key")
        .as_bytes()
        .to_vec()
}

// Encode an RSA public key to a vector of u8
pub fn encode_vk_pkcs1(sk: VerifyingKey<Sha256>) -> Vec<u8> {
    sk.to_pkcs1_der()
        .expect("Unable to encode RSA private key")
        .as_bytes()
        .to_vec()
}

// Decode an RSA private key from a vector of u8
pub fn decode_sk_pkcs1(sk: Vec<u8>) -> BlindedSigningKey<Sha256> {
    let priv_key = RsaPrivateKey::from_pkcs1_der(&sk)
        .expect("Unable to decode RSA private key");
    BlindedSigningKey::<Sha256>::new(priv_key)
}

// Decode an RSA private key from a vector of u8
pub fn decode_vk_pkcs1(sk: Vec<u8>) -> VerifyingKey<Sha256> {
    let pub_key = RsaPublicKey::from_pkcs1_der(&sk)
        .expect("Unable to decode RSA public key");
    VerifyingKey::new(pub_key)
}

// Generate a random seed with ChaCha8Rng
pub fn seed_rng(r: Vec<u8>) -> ChaCha8Rng {
    ChaCha8Rng::from_seed(vec_to_arr(r))
}

// Clone a SAG since its not implemented by the crate
// fn clone_sag(sag: &SAG) -> SAG {
//     SAG {
//         challenge: sag.challenge.clone(),
//         ring: sag.ring.clone(),
//         responses: sag.responses.clone()
//     }
// }