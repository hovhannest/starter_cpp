mod crypto;

fn main() {
    println!("Crypto test:");
    
    // Test key generation
    let keypair = crypto::KeyPair::generate();
    let message = b"Hello, secure world!";
    let signature = keypair.sign(message);
    
    // Verify signature
    if keypair.verify(message, &signature) {
        println!("✓ Signature verification successful");
    } else {
        println!("✗ Signature verification failed");
    }

    // Test session key exchange
    let alice_session = crypto::SessionKey::generate();
    let bob_session = crypto::SessionKey::generate();
    
    // Store public keys before consuming the sessions
    let alice_public = *alice_session.public_key();
    let bob_public = *bob_session.public_key();
    
    let alice_shared = alice_session.exchange(&bob_public);
    let bob_shared = bob_session.exchange(&alice_public);
    
    if alice_shared == bob_shared {
        println!("✓ Key exchange successful (shared secret first bytes: {:02x}{:02x}{:02x}..)",
                alice_shared[0], alice_shared[1], alice_shared[2]);
    } else {
        println!("✗ Key exchange failed");
    }
}