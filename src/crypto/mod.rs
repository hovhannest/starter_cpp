use ed25519_compact::{KeyPair as Ed25519KeyPair, Seed, Signature};
use hkdf::Hkdf;
use sha2::Sha256;

/// Represents a long-term key pair used for signing and verifying messages
#[derive(Clone)]
pub struct KeyPair {
    keypair: Ed25519KeyPair,
}

/// Represents a session key derived using HKDF
pub struct SessionKey {
    key: [u8; 32],
}

impl KeyPair {
    /// Generate a new random key pair
    pub fn generate() -> Self {
        let mut seed_bytes = [0u8; 32];
        getrandom::fill(&mut seed_bytes).expect("Failed to generate random seed");
        let seed = Seed::new(seed_bytes);
        let keypair = Ed25519KeyPair::from_seed(seed);
        Self { keypair }
    }

    /// Get the public verifying key bytes
    pub fn public_key(&self) -> &[u8] {
        self.keypair.pk.as_ref()
    }

    /// Sign a message using the private signing key
    pub fn sign(&self, message: &[u8]) -> [u8; 64] {
        let signature = self.keypair.sk.sign(message, None);
        let mut bytes = [0u8; 64];
        bytes.copy_from_slice(signature.as_ref());
        bytes
    }

    /// Verify a signature using the public verifying key
    pub fn verify(&self, message: &[u8], signature: &[u8; 64]) -> bool {
        if let Ok(sig) = Signature::from_slice(signature) {
            self.keypair.pk.verify(message, &sig).is_ok()
        } else {
            false
        }
    }
}

impl SessionKey {
    /// Generate a new session key using random bytes
    pub fn generate() -> Self {
        let mut key = [0u8; 32];
        getrandom::fill(&mut key).expect("Failed to generate random key");
        Self { key }
    }

    /// Get the session key
    pub fn key(&self) -> &[u8; 32] {
        &self.key
    }

    /// Derive a shared key using HKDF
    pub fn exchange(self, other_key: &[u8; 32]) -> [u8; 32] {
        let hkdf = Hkdf::<Sha256>::new(Some(other_key), &self.key);
        let mut okm = [0u8; 32];
        hkdf.expand(&[], &mut okm).expect("HKDF expand failed");
        okm
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keypair_generation() {
        let keypair = KeyPair::generate();
        assert_eq!(keypair.public_key().len(), 32);
    }

    #[test]
    fn test_sign_and_verify() {
        let keypair = KeyPair::generate();
        let message = b"test message";
        let signature = keypair.sign(message);
        assert!(keypair.verify(message, &signature));
    }

    #[test]
    fn test_session_key_exchange() {
        let alice_session = SessionKey::generate();
        let bob_session = SessionKey::generate();
        
        let alice_key = *alice_session.key();
        let bob_key = *bob_session.key();

        let alice_shared = alice_session.exchange(&bob_key);
        let bob_shared = bob_session.exchange(&alice_key);

        assert_eq!(alice_shared, bob_shared);
    }
}