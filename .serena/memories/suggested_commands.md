# Suggested Commands for Puppy Raffle Development

## Essential Development Commands

### Setup and Installation
```bash
# Initial setup (run once)
make                    # Cleans, installs dependencies, and builds
make install           # Install forge-std, openzeppelin-contracts@v3.4.0, base64
```

### Building and Testing
```bash
forge build            # Build the contracts
forge test             # Run all tests
forge test -vv         # Run tests with verbose output
forge test -vvv        # Run tests with very verbose output
forge test --match-test [TEST_NAME]  # Run specific test
```

### Code Quality and Coverage
```bash
forge fmt              # Format Solidity code
forge coverage         # Generate test coverage report
forge coverage --report debug  # Detailed coverage report
forge snapshot         # Generate gas snapshots
```

### Local Development
```bash
anvil                  # Start local Ethereum node
# (Uses custom mnemonic and 1 second block time)
```

### Utility Commands
```bash
forge clean            # Clean build artifacts
forge update           # Update dependencies
```

## Git Commands (macOS/Darwin)
```bash
git status             # Check git status
git add .              # Stage all changes
git commit -m "message"  # Commit changes
git log --oneline      # View commit history
```

## File System Commands (macOS/Darwin)
```bash
ls -la                 # List files with details
find . -name "*.sol"   # Find Solidity files
grep -r "pattern" src/ # Search for pattern in src directory
cat filename           # Display file contents
```

## Configuration Files
- `foundry.toml`: Foundry configuration (src/out/libs paths, remappings)
- `Makefile`: Build automation and common commands
- `.gitmodules`: Git submodule configuration for dependencies