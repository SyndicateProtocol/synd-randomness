# Syndicate Randomness

A verifiable randomness system built on Syndicate's sequencing infrastructure using Lit Protocol. The project enables on-chain randomness generation through a cross-chain architecture that separates transaction sequencing from randomness injection.

## Architecture Overview

The system uses a cross-chain architecture to provide verifiable randomness to smart contracts:

### ⚡ Sequencing Chain
Handles transaction sequencing and randomness coordination:
- **RandomnessSequencer.sol** - Manages transaction mempool and randomness injection
- **RLPTxBreakdown.sol** - Utilities for decoding RLP transaction data
- **RLPReader.sol** - RLP decoding utilities

### 🎲 Appchain
Consumes randomness for on-chain applications:
- **Random.sol** - Stores and provides verifiable randomness
- **DoSomethingWithRandom.sol** - Example contract demonstrating randomness consumption

### 📡 Indexer (Ponder.sh)
Monitors and responds to randomness requests:
- Watches for `MempoolUpdated` events on RandomnessSequencer
- Triggers Lit Protocol PKP to generate and inject randomness
- Automatically processes queued transactions after randomness injection

## How It Works

1. **Request**: A contract calls a function that requires randomness
2. **Queue**: The RandomnessSequencer holds the transaction in a mempool
3. **Generate**: The indexer detects the queued transaction and triggers Lit Protocol
4. **Inject**: Lit PKP generates verifiable randomness and sends it to the Random contract
5. **Process**: The sequencer processes the randomness transaction, then flushes the mempool

This ensures all transactions requiring randomness are executed in a deterministic order after randomness is available.

## Project Structure

```
synd-randomness/
├── contracts/           # Solidity smart contracts (Foundry)
│   ├── src/
│   │   ├── RandomnessSequencer.sol
│   │   ├── Random.sol
│   │   └── DoSomethingWithRandom.sol
│   ├── script/          # Deployment and configuration scripts
│   └── test/            # Contract tests
├── indexer/             # Ponder indexer with Lit integration
│   ├── src/             # Event handlers
│   └── lit/             # Lit Protocol integration
└── README.md
```

## Key Features

- **Verifiable Randomness**: Powered by Lit Protocol's PKP (Programmable Key Pair)
- **Fair Ordering**: Transactions requiring randomness are held until randomness is available
- **Flexible Allowlist**: Admin-configurable function selectors determine which calls require randomness
- **Cross-Chain**: Separates sequencing concerns from application logic
- **Automated**: Indexer automatically responds to randomness requests

## Getting Started

See individual READMEs for detailed setup instructions:
- [Contracts](./contracts/README.md) - Smart contract deployment and testing
- [Indexer](./indexer/README.md) - Event monitoring and Lit integration

## Use Cases

- Fair NFT mints with randomized traits
- On-chain games with unpredictable outcomes
- Lottery and raffle systems
- Random selection mechanisms
- Any application requiring verifiable, unpredictable randomness

## Security Considerations

- The `RANDOM_ADMIN_ROLE` on RandomnessSequencer controls when randomness is injected
- The `FUNCTION_SELECTOR_ADMIN_ROLE` controls which functions require randomness
- The Lit PKP must be properly secured and have appropriate gas funding
- Randomness is only as secure as the Lit Protocol network

## License

MIT License - see LICENSE file for details
