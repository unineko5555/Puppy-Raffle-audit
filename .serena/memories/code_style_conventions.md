# Code Style and Conventions

## Solidity Version and Pragma
- **Solidity Version**: ^0.7.6 (legacy version for audit practice)
- **Experimental Features**: `pragma experimental ABIEncoderV2;` used in tests

## Import Style
- OpenZeppelin contracts using remapping: `@openzeppelin/contracts`
- Relative imports for project files: `../src/PuppyRaffle.sol`
- External libraries: `lib/base64/base64.sol`

## Contract Structure
- Inheritance pattern: `contract PuppyRaffle is ERC721, Ownable`
- Using statements: `using Address for address payable;`
- State variables organized with visibility and storage packing considerations

## Naming Conventions
- **Contracts**: PascalCase (`PuppyRaffle`, `PuppyRaffleTest`)
- **Functions**: camelCase (`enterRaffle`, `selectWinner`, `changeFeeAddress`)
- **Variables**: camelCase (`entranceFee`, `raffleDuration`, `raffleStartTime`)
- **Constants**: Not clearly established (few constants in codebase)
- **Private functions**: underscore prefix (`_baseURI`, `_isActivePlayer`)

## Testing Conventions
- **Test Contract**: Inherits from `Test` (forge-std)
- **Test Functions**: Prefix with `test` (`testCanEnterRaffle`)
- **Test Setup**: `setUp()` function for initialization
- **Test Organization**: Comments with section headers (`/// EnterRaffle ///`)
- **Test Addresses**: Simple numbered addresses (`address(1)`, `address(2)`)

## Documentation Style
- **NatSpec**: Uses `@title`, `@author`, `@notice` for contract documentation
- **Comments**: Numbered lists for functionality description
- **Inline Notes**: Japanese comments for vulnerability tracking (e.g., `//Note:overflow対策`)

## Gas Optimization Notes
- Storage packing mentioned in comments: "We do some storage packing to save gas"
- Use of `immutable` for `entranceFee`

## Security Considerations
- The codebase includes intentional vulnerabilities for educational purposes
- Notes at top of contract list vulnerability categories (H01-H07, M01-M03, L01-L06)
- Some security fixes are commented out (e.g., overflow protection)