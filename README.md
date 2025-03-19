# Aave Lottery Smart Contract

## Overview
The Aave Lottery is a decentralized smart contract that allows users to stake an ERC20 token into an Aave pool, accumulate interest, and participate in a no-loss lottery system where one participant wins the accumulated interest as a reward while all participants can withdraw their initial stake.

## Features
- Users can enter the lottery by staking an ERC20 token.
- Funds are deposited into Aave to generate yield.
- The lottery runs in rounds with a defined duration.
- A winner is randomly selected based on their stake.
- Users can exit past rounds and withdraw their initial stake.
- The winner claims the accumulated interest as a reward.
- No participant loses their principal deposit.

## Smart Contract Details

### Data Structures
- **Round:** Stores information about each lottery round, including total stake, end time, accumulated award, and winner details.
- **Ticket:** Stores user participation details, such as stake amount and position in the ticket pool.

### Key Variables
- `roundDuration`: The duration of each lottery round.
- `currentID`: Tracks the ongoing round.
- `underlying`: The ERC20 token used for staking.
- `aave`: The Aave lending pool contract.
- `aToken`: The Aave interest-bearing token.
- `Rounds`: Mapping of round ID to round details.
- `Tickets`: Mapping of user participation per round.

## Functions

### `constructor(uint256 _roundDuration, address _underlying, address _aavePool)`
Initializes the contract, sets the ERC20 token and Aave pool, and starts the first lottery round.

### `enter(uint256 _amount)`
- Users deposit funds into the lottery.
- Funds are transferred to the contract and deposited into Aave.
- Tracks the user's stake and position in the round.

### `exit(uint256 roundID)`
- Allows users to withdraw their stake from past rounds (not the current round).
- Transfers the user's stake back to their wallet.

### `claim(uint256 roundID)`
- The winner claims the accumulated interest as a reward.
- Ensures the claim is valid and transfers the reward to the winner.

### `_updateState()`
- Checks if the round has ended.
- Withdraws the funds from Aave.
- Calculates the earned interest.
- Selects a random winner and starts a new round.

### `_drawWinner(uint256 total)`
- Generates a random number to select the winner.
- Uses the total stake and blockchain parameters to ensure randomness.

## How to Deploy and Use

### Prerequisites
- Solidity compiler (0.8.13 or later)
- Hardhat or Foundry for smart contract development
- Aave V3 deployed contracts
- OpenZeppelin ERC20 utilities

### Deployment Steps
1. Clone the repository.
2. Install dependencies (`forge install` or `npm install` if using Hardhat).
3. Compile the contract (`forge build` or `npx hardhat compile`).
4. Deploy to a blockchain network using a script or Hardhat task.

### Example Usage
```solidity
// Deploy the contract with:
// round duration = 1 week, USDC as the underlying asset, and Aave pool address
Aavelottery lottery = new Aavelottery(604800, USDC_ADDRESS, AAVE_POOL_ADDRESS);

// User deposits 100 USDC to participate in the lottery
lottery.enter(100 * 1e6);

// After the round ends, winner claims the reward
lottery.claim(0);
```

## Security Considerations
- Ensures users cannot enter multiple times in the same round.
- Uses SafeERC20 for secure token transfers.
- Prevents claiming the reward multiple times.
- Random number generation uses multiple blockchain parameters for fairness.
- Users can always withdraw their principal deposit, ensuring a no-loss mechanism.

## License
This project is licensed under the MIT License.

