use curve25519_dalek::{scalar::Scalar, ristretto::RistrettoPoint};
use nazgul::{sag::SAG, traits::{Verify, Sign}};
use rand_core::OsRng;
use sha2::Sha512;

pub fn rs_vrfy(signature: SAG, message: Vec<u8>) -> bool {
    SAG::verify::<Sha512>(signature, &message)
}

pub fn rs_sign(secret_idx: usize, sk: Scalar, ring: Vec<RistrettoPoint>, message: Vec<u8>) -> SAG {
    SAG::sign::<Sha512, OsRng>(sk, ring.clone(), secret_idx, &message)
}
