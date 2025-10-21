# Randomness Indexer

A Ponder-based indexer that monitors the RandomnessSequencer contract and automatically triggers randomness generation using Lit Protocol.

## Overview

This indexer watches for transactions that require randomness and automatically:
1. Detects `MempoolUpdated` events from the RandomnessSequencer
2. Generates verifiable randomness using Lit Protocol's PKP (Programmable Key Pair)
3. Injects the randomness into the system
4. Triggers the mempool flush to process queued transactions

## Architecture

### Event Monitoring
The indexer uses Ponder to watch the RandomnessSequencer contract on the sequencing chain (Risa).

### Lit Protocol Integration
When a randomness request is detected:
- Lit Action executes to generate random data
- PKP signs the randomness transaction
- Transaction is submitted to both chains:
  - Random value to the Random contract (Pacifica)
  - Trigger to the RandomnessSequencer (Risa)

## Setup

### Prerequisites
- Node.js >= 18.14
- Bun (recommended) or npm/yarn
- Deployed RandomnessSequencer contract
- Deployed Random contract
- Lit Protocol PKP with appropriate permissions

### Installation

```bash
npm install
# or
bun install
```

### Environment Configuration

Copy and configure the environment file:

```bash
cp .env.example .env
```

Required variables:
```env
# Chain Configuration
SEQUENCING_CHAIN_ID=<chain-id>
SEQUENCING_CHAIN_RPC_URL=<risa-rpc-url>
APPCHAIN_RPC_URL=<pacifica-rpc-url>
APPCHAIN_CHAIN_ID=<chain-id>

# Contract Addresses
RANDOMNESS_SEQUENCER_CONTRACT_ADDRESS=<sequencer-address>
RANDOM_CONTRACT_ADDRESS=<random-address>

# Lit Protocol
LIT_PKP_PUBLIC_KEY=<pkp-public-key>
LIT_PKP_ETH_ADDRESS=<pkp-eth-address>

# Private Keys (for development/testing)
LIT_CAPACITY_CREDIT_TOKEN_ID=<capacity-credit-token-id>
```

### Lit Protocol Setup

The indexer requires a Lit Protocol PKP (Programmable Key Pair) to sign randomness transactions.

#### Mint a PKP

```bash
npm run mintPkp
# or
bun run mintPkp
```

This will:
- Create a new PKP on the Lit network
- Output the PKP public key and ETH address
- Store the PKP info for later use

**Important**: Save the PKP details and update your `.env` file with:
- `LIT_PKP_PUBLIC_KEY`
- `LIT_PKP_ETH_ADDRESS`

#### Fund the PKP

The PKP needs native tokens on both chains to send transactions. Send ETH to the `LIT_PKP_ETH_ADDRESS` on both Risa (sequencing chain) and Pacifica (application chain).

#### Grant PKP Permissions

The PKP needs the `RANDOM_ADMIN_ROLE` on both contracts. From the contracts directory, run:

```bash
# Grant RANDOM_ADMIN_ROLE on RandomnessSequencer (Risa)
make add-randomness-sequencer-admin

# Grant RANDOM_ADMIN_ROLE on Random (Pacifica)
make add-random-admin
```

## Running

### Development Mode

Start the indexer in development mode with hot reloading:

```bash
npm run dev
# or
bun run dev
```

### Production Mode

Start the indexer in production mode:

```bash
npm run start
# or
bun run start
```

### Database Management

Access the Ponder database CLI:

```bash
npm run db
# or
bun run db
```

## Testing

### Test Lit Integration

Test the Lit Protocol integration without running the full indexer:

```bash
npm run doLit
# or
bun run doLit
```

This will:
- Connect to Lit Protocol
- Execute the randomness generation action
- Output the generated transaction
- Exit without sending it

## How It Works

### Event Handler

The indexer listens for `MempoolUpdated` events:

```typescript
ponder.on("RandomnessSequencer:MempoolUpdated", async (event) => {
  // Generate randomness via Lit Protocol
  const { sequencerTransaction } = await getLitRandomnessSequencerTransaction()

  // Send to sequencing chain
  const hash = await risaPublicClient.sendRawTransaction({
    serializedTransaction: sequencerTransaction,
  })
})
```

### Lit Action

The Lit Action performs several tasks:
1. Fetches random data from Drand (distributed randomness beacon)
2. Generates the transaction to update the Random contract
3. Generates the transaction to trigger the RandomnessSequencer
4. Signs both transactions using the PKP
5. Returns the signed transactions to the indexer

### Transaction Flow

1. **Trigger**: User transaction requiring randomness is detected
2. **Event**: RandomnessSequencer emits `MempoolUpdated`
3. **Listen**: Indexer receives event via Ponder
4. **Generate**: Lit Action creates and signs randomness transactions
5. **Inject**: Indexer submits transactions to both chains
6. **Process**: RandomnessSequencer processes randomness and flushes mempool

## Development

### Linting

```bash
npm run lint
# or
bun run lint
```

### Type Checking

```bash
npm run typecheck
# or
bun run typecheck
```

### Code Generation

Regenerate Ponder types and ABIs:

```bash
npm run codegen
# or
bun run codegen
```

## Monitoring

The indexer logs important events:

```
Generating randomness...
Randomness injection sent to sequencer: 0x1234...
```

Errors are logged with details:

```
Error sending transaction: <error details>
```

## Troubleshooting

### PKP has insufficient funds
- Ensure the PKP has enough native tokens on both chains

### PKP lacks permissions
- Verify the PKP has `RANDOM_ADMIN_ROLE` on both contracts (see Grant PKP Permissions section)

### Lit Protocol connection issues
- Check your Lit capacity credit token ID is valid
- Ensure you're using the correct Lit network (testnet vs mainnet)

### Events not being detected
- Verify the `RANDOMNESS_SEQUENCER_CONTRACT_ADDRESS` is correct
- Check the contract is deployed on the correct chain
- Ensure the indexer started from the correct block

## License

MIT License - see LICENSE file for details
