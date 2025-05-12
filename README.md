# P2P Overlay Network

A lightweight peer-to-peer overlay network implementation in Rust, focusing on minimal binary size, security, and performance.

## Project Overview

This project implements a P2P overlay network with:
- Multiple transport protocol support (TCP, QUIC)
- Strong cryptographic security
- Efficient relay protocols
- Minimal binary size
- High performance

## Documentation Structure

### 1. Implementation
- [Detailed Implementation Plan](detailed_implementation_plan.md)
- [Code Structure](code_structure.md)
- [Error Handling Guidelines](error_handling_guidelines.md)

### 2. Protocols and Specifications
- [Transport Layer Specification](transport_layer_spec.md)
- [Relay Protocol Specification](relay_protocol_spec.md)

### 3. Security and Performance
- [Security Audit Checklist](security_audit_checklist.md)
- [Performance Optimization Guide](performance_optimization_guide.md)

## Requirements

- Rust nightly toolchain
- Add `rust-src` component:
  ```bash
  rustup toolchain install nightly
  rustup component add rust-src --toolchain nightly
  ```

## Building

Build with size optimizations:
```bash
cargo +nightly build -Z build-std=std,panic_abort -Z build-std-features=optimize_for_size,panic_immediate_abort --profile minsizerel
```

Run tests:
```bash
cargo +nightly test
```

## Project Structure

```
src/
├── crypto/         # Cryptographic operations
├── transport/      # Transport layer implementations
├── relay/          # Relay protocol implementation
├── network/        # Network management
├── protocol/       # Protocol definitions
└── utils/          # Utility functions
```

## Implementation Status

### Phase A: Core Cryptographic Infrastructure
- [x] Project setup
- [x] Basic key types
- [ ] Message encryption
- [ ] Session management

### Phase B: Network Transport Layer
- [ ] Transport traits
- [ ] TCP implementation
- [ ] QUIC implementation
- [ ] Transport selection

### Phase C: Relay Infrastructure
- [ ] Circuit creation
- [ ] Message routing
- [ ] Node management
- [ ] Path selection

### Phase D: Failure and Churn Management
- [ ] Health monitoring
- [ ] Failure detection
- [ ] Node replacement
- [ ] State recovery

### Phase E: Anonymity Features
- [ ] Traffic obfuscation
- [ ] Path randomization
- [ ] Dummy traffic
- [ ] Pattern breaking

## Contributing

1. Review the [Detailed Implementation Plan](detailed_implementation_plan.md)
2. Follow the [Error Handling Guidelines](error_handling_guidelines.md)
3. Ensure code meets [Security Audit Checklist](security_audit_checklist.md)
4. Optimize according to [Performance Optimization Guide](performance_optimization_guide.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.