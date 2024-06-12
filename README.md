# BasedVault

BasedVault is a vault contract built on top of the Synthetix V3 protocol, utilizing the ERC-4626 standard for tokenized vaults. It allows users to stake assets (e.g., USDC) and earn rewards from the Synthetix liquidity pools.

## Prerequisites

- Node.js
- Foundry
- Cannon

## Installation

1. Install Node.js from [Node.js](https://nodejs.org/).

2. Install Cannon globally:
   ```sh
   npm install -g @usecannon/cli
   ```
3. Install Foundry:
   ```sh
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

## Project Setup

1. Clone the repository:

   ```sh
   git clone https://github.com/your-repo/basedvault.git
   cd basedvault
   ```

2. Add libraries for foundry:

   ```sh
   forge install usecannon/cannon-std
   forge install OpenZeppelin/openzeppelin-contracts
   ```

## Deployment

1. Compile the contracts:

   ```sh
   cannon build
   ```

2. Deploy the contracts:
   ```sh
   cannon build --network REPLACE_WITH_RPC_ENDPOINT --private-key REPLACE_WITH_KEY_THAT_HAS_GAS_TOKENS
   ```

## Interaction

1. Run the interaction script:
   ```sh
   cannon run scripts/interact.js
   ```

## Testing

1. Run the tests:
   ```sh
   npx cannon test
   ```
