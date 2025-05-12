# Relay Protocol Specification

## Overview

The relay protocol defines how nodes communicate to establish circuits, relay messages, and maintain anonymity in the network.

## Circuit Establishment

### 1. Circuit Creation
```rust
pub struct Circuit {
    /// Unique circuit identifier
    id: CircuitId,
    
    /// List of relay nodes in the circuit
    nodes: Vec<RelayNode>,
    
    /// Layered encryption keys for each hop
    keys: Vec<SessionKey>,
    
    /// Circuit state
    state: CircuitState,
    
    /// Circuit creation timestamp
    created_at: SystemTime,
}
```

### 2. Circuit Building Protocol

```
[Client] -> [Entry Node] -> [Middle Node] -> [Exit Node]

1. CREATE_CIRCUIT
   Client -> Entry: {
       circuit_id: [random_id],
       pub_key: [client_ephemeral_key],
       signature: [signed_with_identity_key]
   }

2. EXTEND_CIRCUIT
   Entry -> Middle: {
       circuit_id: [random_id],
       pub_key: [client_ephemeral_key],
       layer_key: [encrypted_session_key]
   }

3. CIRCUIT_EXTENDED
   Middle -> Entry -> Client: {
       circuit_id: [id],
       status: "extended",
       node_key: [node_public_key]
   }
```

## Message Format

### 1. Cell Structure
```rust
pub struct Cell {
    /// Circuit identifier
    circuit_id: CircuitId,
    
    /// Command type
    command: Command,
    
    /// Payload length
    length: u16,
    
    /// Cell payload
    payload: Vec<u8>,
}

pub enum Command {
    Create,
    Created,
    Destroy,
    RelayData,
    RelayBegin,
    RelayEnd,
    RelayExtend,
    RelayExtended,
}
```

### 2. Onion Routing Format
```rust
pub struct OnionPacket {
    /// Layered encrypted payload
    payload: Vec<u8>,
    
    /// Per-hop headers
    headers: Vec<EncryptedHeader>,
    
    /// Integrity check
    mac: [u8; 32],
}
```

## Circuit Management

### 1. Circuit States
```rust
pub enum CircuitState {
    Building {
        attempts: u32,
        timeout: Duration,
    },
    Established {
        established_at: SystemTime,
        last_used: SystemTime,
    },
    Failing {
        error: CircuitError,
        recovery_attempts: u32,
    },
    Destroyed {
        reason: DestroyReason,
        timestamp: SystemTime,
    },
}
```

### 2. Circuit Selection
```rust
pub struct CircuitSelection {
    /// Circuit building strategy
    strategy: BuildStrategy,
    
    /// Path selection parameters
    path_params: PathParams,
    
    /// Performance requirements
    requirements: CircuitRequirements,
}
```

## Relay Node Protocol

### 1. Node States
```rust
pub enum NodeState {
    Available {
        capacity: ResourceCapacity,
        current_load: ResourceUsage,
    },
    Busy {
        estimated_availability: Duration,
    },
    Maintenance {
        reason: MaintenanceReason,
        duration: Duration,
    },
    Offline {
        last_seen: SystemTime,
        return_estimate: Option<SystemTime>,
    },
}
```

### 2. Resource Management
```rust
pub struct ResourceCapacity {
    max_circuits: u32,
    max_bandwidth: u64,
    max_memory: u64,
}

pub struct ResourceUsage {
    active_circuits: u32,
    bandwidth_used: u64,
    memory_used: u64,
}
```

## Circuit Building

### 1. Path Selection
```rust
pub struct PathSelection {
    /// Entry node requirements
    entry_requirements: NodeRequirements,
    
    /// Middle node requirements
    middle_requirements: NodeRequirements,
    
    /// Exit node requirements
    exit_requirements: NodeRequirements,
}

pub struct NodeRequirements {
    min_uptime: Duration,
    min_bandwidth: u64,
    allowed_countries: Vec<String>,
    excluded_nodes: Vec<NodeId>,
}
```

### 2. Circuit Building Strategy
```rust
pub enum BuildStrategy {
    /// Balance between speed and anonymity
    Balanced {
        timeout: Duration,
        max_attempts: u32,
    },
    /// Prioritize speed
    Fast {
        max_latency: Duration,
        min_bandwidth: u64,
    },
    /// Prioritize anonymity
    Anonymous {
        min_path_length: u32,
        required_jurisdictions: u32,
    },
}
```

## Error Handling

### 1. Circuit Errors
```rust
pub enum CircuitError {
    BuildTimeout(Duration),
    NodeFailure(NodeId),
    PathError(PathSelectionError),
    ProtocolError(ProtocolViolation),
    ResourceExhausted(ResourceType),
}
```

### 2. Error Recovery
```rust
pub struct ErrorRecovery {
    /// Maximum recovery attempts
    max_attempts: u32,
    
    /// Backoff strategy
    backoff: BackoffStrategy,
    
    /// Recovery actions
    actions: Vec<RecoveryAction>,
}
```

## Performance Optimization

### 1. Circuit Prebuilding
- Maintain a pool of pre-built circuits
- Predict circuit demand
- Balance resource usage
- Optimize build timing

### 2. Resource Management
- Circuit multiplexing
- Load balancing
- Congestion control
- Resource reservation

### 3. Optimizations
- Minimize latency
- Reduce bandwidth overhead
- Optimize memory usage
- Efficient key management

## Security Considerations

### 1. Traffic Analysis Prevention
- Padding
- Timing randomization
- Dummy traffic
- Circuit isolation

### 2. Node Selection Security
- Geographic distribution
- Jurisdiction diversity
- Reputation checking
- Performance verification

## Testing Requirements

### 1. Protocol Testing
- Handshake verification
- Circuit building
- Message relay
- Error handling

### 2. Performance Testing
- Latency measurement
- Throughput testing
- Resource utilization
- Scalability testing

### 3. Security Testing
- Attack simulation
- Protocol verification
- Privacy analysis
- Stress testing

## Documentation Requirements

### 1. Protocol Documentation
- Message formats
- State transitions
- Error codes
- Recovery procedures

### 2. Implementation Guidelines
- Best practices
- Security considerations
- Performance optimization
- Testing procedures