# Puppy Raffle Project Overview

## Purpose
This is a Solidity smart contract audit codebase for "First Flight #2: Puppy Raffle". It's a raffle system where users can enter to win cute dog NFTs. This appears to be an intentionally vulnerable contract for educational/audit practice purposes, as evidenced by the notes in the contract listing various vulnerability categories (H01-H07, M01-M03, L01-L06).

## Key Functionality
- Users enter raffle by calling `enterRaffle` with participant addresses
- Duplicate addresses are not allowed
- Users can get refunds via `refund` function
- Winner is selected after X seconds using `selectWinner`
- Owner takes fees, remainder goes to winner
- Winner receives an NFT

## Tech Stack
- **Solidity**: ^0.7.6 (older version for vulnerability demonstration)
- **Foundry**: For development, testing, and deployment
- **OpenZeppelin**: ERC721, Ownable, Address utilities (v3.4.0)
- **Base64**: For NFT metadata encoding
- **Forge-std**: Testing framework

## Contract Architecture
- Main contract: `src/PuppyRaffle.sol` (inherits from ERC721, Ownable)
- Test suite: `test/PuppyRaffleTest.t.sol` with 21 test functions
- Deployment script: `script/DeployPuppyRaffle.sol`

## Audit Context
- This is an educational audit codebase from Cyfrin Updraft
- Commit Hash: 22bbbb2c47f3f2b78c1b134590baf41383fd354f
- Target Chain: Ethereum
- nSLOC: 143, Complexity Score: 111
- Contest Period: Oct 25 - Nov 01, 2023