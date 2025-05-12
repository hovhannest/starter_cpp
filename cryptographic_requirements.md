# Cryptographic Requirements for the P2P Overlay Network

## Background and Discussion

### Key Question
Can we validate that a message is from our client and not from a bad actor if we implement Perfect Forward Secrecy (PFS)? If yes, PFS is the preferable option.

### Proposal: Perfect Forward Secrecy (PFS) with Client Validation

#### Mechanism
1. **Ephemeral Key Exchange**:
   - Use Diffie-Hellman over Curve25519 to establish session keys for encrypted communication.
   - Each session key is unique and discarded after use.

2. **Client Authentication**:
   - Combine PFS with public-key cryptography for client validation.
   - Each client has a long-term private/public key pair.
   - During the handshake, clients sign their ephemeral public keys with their long-term private keys.
   - The recipient verifies the signature using the sender's long-term public key.

3. **Message Signing**:
   - All messages are signed with the sender's long-term private key.
   - The recipient verifies the signature to ensure authenticity and integrity.

#### Advantages
- **Anonymity**: PFS ensures that session keys are temporary, making it difficult to trace communication back to the sender.
- **Security**: Even if a private key is compromised, past communications remain secure.
- **Client Validation**: Public-key cryptography ensures that only legitimate clients can participate in the network.

#### Challenges
- **Key Management**:
  - Clients must securely store their long-term private keys.
  - A compromised private key could allow an attacker to impersonate the client.

- **Computational Overhead**:
  - PFS and public-key cryptography add computational complexity, which may impact performance on resource-constrained devices.

- **Bootstrap Trust**:
  - Initial trust in a client's public key must be established (e.g., through a trusted bootstrap mechanism).

---

## Cryptographic Requirements

### Message Integrity
- Use cryptographic signatures (e.g., Ed25519) to ensure that messages are not tampered with during transit.
- Each message is signed by the sender and verified by the recipient.

### Message Confidentiality
- Employ end-to-end encryption (e.g., X25519 for key exchange and AES-GCM for encryption) to secure message content.
- Each relay decrypts only its layer of the message (onion encryption) to reveal the next hop.

### Authentication
- Nodes authenticate each other using public key infrastructure (PKI) or a decentralized alternative like Web of Trust.
- Bootstrap nodes distribute public keys securely to prevent impersonation.

### Forward Secrecy
- Implement ephemeral key exchanges for each session to ensure that past communications remain secure even if long-term keys are compromised.

### Replay Protection
- Include unique nonces or timestamps in messages to prevent replay attacks.
- Relays and recipients reject messages with duplicate or outdated nonces.

### Dummy Traffic
- Generate cryptographically indistinguishable dummy messages to obscure real communication patterns.
- Relays periodically send dummy traffic to prevent traffic analysis.

---

## Next Steps
1. Define the cryptographic protocols and libraries to be used (e.g., RustCrypto crates for Ed25519, X25519, and AES-GCM).
2. Implement a secure key exchange mechanism for nodes joining the network.
3. Develop the logic for layered encryption and decryption at relays.
4. Test the cryptographic implementation for performance and security under various attack scenarios.
5. Design a secure mechanism for distributing and verifying client public keys during the bootstrap process.
### RSA-Based Key Distribution Mechanism

We have chosen RSA for encryption due to its robust security features. The public keys will be distributed using a pre-shared key embedded directly in the client application. This approach ensures simplicity and avoids runtime dependencies on external services.

#### Key Distribution Details:
1. **Key Generation**:
   - RSA keys will be generated during the bootstrap node setup process.
   - Public keys will be embedded in the client application at build time.

2. **Key Embedding**:
   - The public key will be hardcoded into the client application to ensure secure distribution.
   - Updates to the public key will require a new application build and deployment.

3. **Security Considerations**:
   - The private key will remain securely stored on the bootstrap node.
   - Regular audits will be conducted to ensure the integrity of the key storage.

4. **Limitations**:
   - Key updates require application redeployment, which may introduce delays in key rotation.
   - This approach is less flexible compared to dynamic key distribution methods.

#### Next Steps:
- Implement the RSA key generation and embedding process.
- Develop bootstrap node logic for encrypted communication.
- Test the system for security and performance.