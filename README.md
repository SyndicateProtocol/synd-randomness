# Syndicate Randomness Infrastructure

A generalized randomness injection system built on Syndicate's sequencing infrastructure. This project provides configurable, verifiable randomness for blockchain applications through a cross-chain architecture that separates transaction sequencing from execution.

## Overview

This infrastructure enables applications to inject verifiable randomness into smart contract transactions by coordinating between a sequencing chain and an application chain.

## Architecture

The system uses a cross-chain architecture to optimize for both security and performance:

### 🎮 Application Chain Contracts
These contracts consume randomness for application logic:
- **Random.sol** - Stores and provides verifiable randomness values

### ⚡ Sequencing Chain Contracts
These contracts handle transaction sequencing and randomness coordination:
- **SequencingBundler.sol** - Bundles transactions and coordinates randomness injection
- **RLPTxBreakdown.sol** - Utilities for decoding RLP transaction data
- **RLPReader.sol** - RLP decoding utilities


## How It Works

### Transaction Flow

1. **Transaction Submission**: Users submit transactions to the appchain
2. **Signature Detection**: The SequencingBundler detects if a contract interaction requires randomness based on the request contract address and function signature
3. **Mempool Holding**: Matching transactions are held in a mempool awaiting randomness
4. **Randomness Injection**: When randomness is provided, it's injected into the appchain at the top of the block
5. **Batch Processing**: All held transactions are processed in order after randomness injection

### Configurable Function Signatures

The system supports dynamic configuration of which function signatures require randomness:

```solidity
// Add a function signature that requires randomness
bundler.addFunctionSelector(0x183ff085); // Example: checkIn()

// Remove a function signature
bundler.removeFunctionSelector(0x183ff085);

// View all configured selectors
bytes4[] memory selectors = bundler.getRandomnessRequiredSelectors();
```

### Nonce Tracking

The system maintains transaction nonces per:
- Contract address
- User address
- Function selector

This ensures proper ordering and prevents replay attacks across different function types.

## Key Features

- **Multi-Signature Support**: Configure any number of function signatures to require randomness
- **Role-Based Access Control**: Separate roles for randomness providers, sequencers, and function selector admins
- **Verifiable Randomness**: On-chain verification of randomness sources
- **Gas Efficiency**: Batch processing of transactions after randomness injection
- **Flexible Integration**: Generic design supports any application requiring randomness

## Access Roles

The system defines several roles for secure operation:

- **DEFAULT_ADMIN_ROLE**: Full administrative control
- **RANDOMNESS_ROLE**: Can inject randomness values
- **SEQUENCER_ROLE**: Can submit transactions for sequencing
- **FUNCTION_SELECTOR_ADMIN_ROLE**: Can add/remove function signatures requiring randomness
- **RANDOMNESS_ADMIN_ROLE**: Can update randomness values on the application chain

## Smart Contracts

### SequencingBundler

The core sequencing contract that:
- Detects transactions calling configured function signatures
- Holds transactions in the mempool until randomness is provided
- Processes transactions in order after randomness injection
- Maintains per-user, per-contract, per-function nonces

Key functions:
```solidity
function addFunctionSelector(bytes4 selector) external
function removeFunctionSelector(bytes4 selector) external
function addRandomness(bytes calldata randomnessTx) external
function processTransaction(bytes calldata txn) public
```

### Random

Simple randomness storage contract that:
- Stores the current randomness value
- Provides access-controlled updates
- Integrates with application logic

Key functions:
```solidity
function setRandom(uint256 _random) external
```

## Integration Example

To integrate this randomness infrastructure into your application:

1. **Deploy Contracts**: Deploy Random.sol on your application chain and SequencingBundler.sol on the sequencing chain
2. **Configure Roles**: Set up appropriate role assignments
3. **Add Function Signatures**: Configure which function signatures should wait for randomness
4. **Submit Transactions**: Route transactions through the sequencing chain
5. **Inject Randomness**: Provide randomness values through the RANDOMNESS_ROLE

## Use Cases

This infrastructure supports any blockchain application requiring verifiable randomness:

- **Gaming**: Fair random outcomes, loot drops, matchmaking
- **DeFi**: Random validator selection, fair token distributions
- **NFTs**: Random trait generation, fair minting queues
- **DAOs**: Random voting delegation, committee selection

## Project Structure

```
clanker-randomness/
├── contracts/
│   ├── src/
│   │   ├── Random.sol                    # Application chain randomness storage
│   │   ├── SequencingBundler.sol        # Sequencing chain bundler
│   │   ├── RLP/
│   │   │   ├── RLPReader.sol            # RLP decoding utilities
│   │   │   └── RLPTxBreakdown.sol       # Transaction decoding
│   │   └── interfaces/
│   │       ├── IRandom.sol              # Randomness interface
│   │       └── ISequencingChain.sol     # Sequencing interface
│   └── test/                            # Contract tests
└── README.md
```

## Security Considerations

- **Randomness Source**: Ensure your randomness source is truly random and verifiable
- **Role Management**: Carefully manage role assignments and permissions
- **Front-Running**: The sequencing architecture helps mitigate front-running attacks
- **Nonce Tracking**: Per-function nonce tracking prevents replay attacks

## License

MIT License - see LICENSE file for details

## Related Projects

This infrastructure is a generalized version of the randomness system originally developed for [Adrift](https://github.com/syndicateio/adrift).
