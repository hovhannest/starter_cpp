use ring::signature::{Ed25519KeyPair, KeyPair as RingKeyPair, UnparsedPublicKey, ED25519};
use x25519_dalek::{self, EphemeralSecret, PublicKey};
use rand_core::OsRng;

/// Represents a long-term key pair used for signing and verifying messages
#[derive(Clone)]
pub struct KeyPair {
    key_bytes: Vec<u8>,
    public_key: Vec<u8>,
}

/// Represents an ephemeral session key used for X25519 key exchange
pub struct SessionKey {
    secret: EphemeralSecret,
    public: x25519_dalek::PublicKey,
}

impl KeyPair {
    /// Generate a new random key pair
    pub fn generate() -> Self {
        let rng = ring::rand::SystemRandom::new();
        let pkcs8_bytes = Ed25519KeyPair::generate_pkcs8(&rng)
            .expect("Failed to generate key pair");
        let key_pair = Ed25519KeyPair::from_pkcs8(pkcs8_bytes.as_ref())
            .expect("Failed to parse key pair");
        let public_key = RingKeyPair::public_key(&key_pair).as_ref().to_vec();
        
        Self {
            key_bytes: pkcs8_bytes.as_ref().to_vec(),
            public_key,
        }
    }

    /// Get the public verifying key bytes
    pub fn public_key(&self) -> &[u8] {
        &self.public_key
    }

    /// Sign a message using the private signing key
    pub fn sign(&self, message: &[u8]) -> [u8; 64] {
        let key_pair = Ed25519KeyPair::from_pkcs8(&self.key_bytes)
            .expect("Failed to parse key pair");
        let sig = key_pair.sign(message);
        let mut bytes = [0u8; 64];
        bytes.copy_from_slice(sig.as_ref());
        bytes
    }

    /// Verify a signature using the public verifying key
    pub fn verify(&self, message: &[u8], signature: &[u8; 64]) -> bool {
        let public_key = UnparsedPublicKey::new(&ED25519, &self.public_key);
        public_key.verify(message, signature).is_ok()
    }
}

impl SessionKey {
    /// Generate a new random session key pair
    pub fn generate() -> Self {
        let secret = EphemeralSecret::random_from_rng(OsRng);
        let public = PublicKey::from(&secret);

        Self { secret, public }
    }

    /// Get the public key
    pub fn public_key(&self) -> &PublicKey {
        &self.public
    }

    /// Perform Diffie-Hellman key exchange with another public key
    pub fn exchange(self, other_public: &PublicKey) -> [u8; 32] {
        self.secret.diffie_hellman(other_public).to_bytes()
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
        
        // Store public keys before consuming the sessions
        let alice_public = *alice_session.public_key();
        let bob_public = *bob_session.public_key();

        let alice_shared = alice_session.exchange(&bob_public);
        let bob_shared = bob_session.exchange(&alice_public);

        assert_eq!(alice_shared, bob_shared);
    }
}