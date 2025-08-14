# Codebase Structure

## Directory Layout
```
2023-10-Puppy-Raffle/
├── src/
│   └── PuppyRaffle.sol          # Main raffle contract (143 nSLOC)
├── test/
│   └── PuppyRaffleTest.t.sol    # Comprehensive test suite (21 tests)
├── script/
│   └── DeployPuppyRaffle.sol    # Deployment script
├── lib/                         # Dependencies (git submodules)
│   ├── forge-std/               # Foundry testing framework
│   ├── openzeppelin-contracts/  # OpenZeppelin v3.4.0
│   └── base64/                  # Base64 encoding library
├── images/                      # Project images/assets
├── foundry.toml                 # Foundry configuration
├── Makefile                     # Build automation
├── README.md                    # Project documentation
└── .gitmodules                  # Git submodule configuration
```

## Core Contract Architecture

### PuppyRaffle.sol
**Inheritance**: `ERC721, Ownable`
**Key State Variables**:
- `entranceFee` (immutable)
- `players[]` (dynamic array)
- `raffleDuration`, `raffleStartTime`
- `feeAddress`, `previousWinner`

**Main Functions**:
- `enterRaffle(address[] participants)` - Enter raffle with multiple addresses
- `refund()` - Get refund for raffle entry
- `selectWinner()` - Draw winner after duration expires
- `withdrawFees()` - Owner withdraws accumulated fees
- `changeFeeAddress()` - Owner changes fee recipient

**Internal Functions**:
- `_baseURI()` - NFT base URI
- `_isActivePlayer()` - Check if address is active player
- `getActivePlayerIndex()` - Get player's index in array

### Test Structure
**Test Categories**:
- Enter Raffle Tests (6 tests)
- Refund Tests (3 tests)  
- Winner Selection Tests (4 tests)
- Fee Management Tests (2 tests)
- Utility Tests (6 tests)

**Test Patterns**:
- Setup with standard parameters (1 ETH fee, 1 day duration)
- Use of numbered test addresses (address(1), address(2), etc.)
- Comprehensive edge case coverage
- Gas optimization testing (`testOverflow`)

## Dependencies and Remappings
- **OpenZeppelin v3.4.0**: ERC721, Ownable, Address utilities
- **Forge-std**: Testing framework and utilities
- **Base64**: NFT metadata encoding
- **Remapping**: `@openzeppelin/contracts=lib/openzeppelin-contracts/contracts`

## Configuration Files
- **foundry.toml**: Build configuration (src/out/libs paths)
- **Makefile**: Automation for clean, install, build, test, format
- **.gitmodules**: Manages external dependencies as submodules