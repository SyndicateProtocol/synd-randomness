# Randomness Contracts

Solidity smart contracts for the Syndicate Randomness system, built with Foundry.

## Contracts

### RandomnessSequencer.sol
Deployed on the sequencing chain, this contract manages transaction sequencing and randomness coordination.

**Key Features:**
- Maintains a mempool of transactions awaiting randomness
- Allowlist-based system to control which contract functions require randomness
- Role-based access control for admin operations
- Processes randomness injection and flushes queued transactions

**Roles:**
- `RANDOM_ADMIN_ROLE` - Can inject randomness transactions
- `SEQUENCER_ADMIN_ROLE` - Can process regular transactions
- `FUNCTION_SELECTOR_ADMIN_ROLE` - Can manage the function allowlist
- `DEFAULT_ADMIN_ROLE` - Can grant/revoke other roles

**Key Functions:**
- `addToFunctionAllowlist(address, bytes4)` - Add a function that requires randomness
- `removeFromFunctionAllowlist(address, bytes4)` - Remove a function from the allowlist
- `processTransaction(bytes)` - Process a transaction (queues if randomness required)
- `processRandomTransaction(bytes)` - Inject randomness and flush mempool

### Random.sol
Deployed on the appchain, this contract stores the current randomness value.

**Key Features:**
- Simple storage contract for the current random value
- Can only be updated by the `RANDOM_ADMIN_ROLE`
- Provides a public `random()` getter for contracts to consume

**Roles:**
- `RANDOM_ADMIN_ROLE` - Can set new random values (typically held by Lit PKP)
- `DEFAULT_ADMIN_ROLE` - Can grant/revoke other roles

### DoSomethingWithRandom.sol
Example contract demonstrating how to consume randomness from the Random contract.

**Usage:**
```solidity
function doSomethingWithRandom() external returns (uint256) {
    uint256 rand = random.random();
    emit GotRandom(rand);
    return rand;
}
```

## Setup

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Private keys for deployment and admin roles

### Installation

```bash
forge install
```

### Environment Configuration

Copy and configure the environment file:

```bash
cp .env.example .env
```

Required variables:
```env
# RPC URLs
SEQUENCING_CHAIN_RPC_URL=<sequencing-chain-rpc-url>
APPCHAIN_RPC_URL=<appchain-rpc-url>

# Private Keys
DEPLOYER_PRIVATE_KEY=<deployer-private-key>
FUNCTION_SELECTOR_ADMIN_PRIVATE_KEY=<admin-private-key>
RANDOMNESS_SEQUENCER_DEFAULT_ADMIN_PRIVATE_KEY=<admin-private-key>
RANDOM_DEFAULT_ADMIN_PRIVATE_KEY=<admin-private-key>
ALLOWLIST_PERMISSION_MODULE_OWNER_PRIVATE_KEY=<owner-private-key>

# Admin Addresses
RANDOM_ADMIN=<lit-pkp-eth-address>
SEQUENCER_ADMIN=<syndicate-sequencer-address>
FUNCTION_SELECTOR_ADMIN=<admin-address>
RANDOMNESS_SEQUENCER_DEFAULT_ADMIN=<admin-address>
RANDOM_DEFAULT_ADMIN=<admin-address>

# Contract Addresses (filled after deployment)
SEQUENCING_CONTRACT_ADDRESS=<syndicate-sequencing-chain-address>
RANDOMNESS_SEQUENCER_CONTRACT_ADDRESS=<address>
RANDOM_CONTRACT_ADDRESS=<address>
TARGET_CONTRACT_ADDRESS=<address>
TARGET_FUNCTION_SIGNATURE=<function-signature>
ALLOWLIST_PERMISSION_MODULE_ADDRESS=<address>
```

## Testing

Run the full test suite:

```bash
forge test
```

Run with verbose output:

```bash
forge test -vvv
```

Run specific tests:

```bash
forge test --match-contract RandomnessSequencerTest
forge test --match-test testAddToFunctionAllowlist
```

## Deployment

All deployment and configuration is handled via the Makefile. See the [Makefile](Makefile) for available commands.

### Deploy Contracts

```bash
# Deploy RandomnessSequencer (on sequencing chain)
make deploy-sequencer

# Deploy Random (on appchain)
make deploy-random

# Deploy example contract (on appchain)
make deploy-do-something-with-random
```

### Configuration

After deployment, configure the system:

```bash
# Add a function to the randomness allowlist
make allowlist-function

# Allowlist the RandomnessSequencer on Syndicate's sequencing chain
make allowlist-randomness-sequencer
```

### Query Contracts

```bash
# View all allowlisted functions
make get-functions
```

## Development

### Build

```bash
forge build
```

### Format

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

## Architecture Notes

### Transaction Flow

1. User submits transaction to sequencing chain
2. RandomnessSequencer checks if function requires randomness
3. If yes, transaction is queued in mempool
4. If no, transaction is immediately processed
5. When randomness is injected via `processRandomTransaction()`, the mempool is flushed

### RLP Decoding

The RandomnessSequencer uses RLP decoding to extract function selectors from transaction calldata, enabling it to determine if a transaction requires randomness before processing.

## License

MIT License - see LICENSE file for details
