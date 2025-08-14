# Task Completion Checklist

## When a Development Task is Completed

### 1. Code Quality Checks
```bash
forge fmt              # Format code according to Solidity standards
forge build            # Ensure code compiles without errors
```

### 2. Testing Requirements
```bash
forge test             # Run all tests to ensure nothing is broken
forge test -vv         # Use verbose output to see detailed results
forge coverage         # Check test coverage if adding new functionality
```

### 3. Gas Optimization Review
```bash
forge snapshot         # Generate gas snapshots to check for regressions
```

### 4. Security Considerations
- **Manual Review**: Check for common vulnerabilities since this is an audit codebase
- **Access Control**: Verify proper use of `onlyOwner` and other modifiers
- **Input Validation**: Ensure proper validation of function parameters
- **Reentrancy**: Check for potential reentrancy issues
- **Integer Overflow/Underflow**: Be aware this uses Solidity ^0.7.6 (no built-in overflow protection)

### 5. Documentation Updates
- Update inline comments if modifying logic
- Ensure NatSpec documentation is accurate
- Update README.md if functionality changes significantly

### 6. Git Workflow
```bash
git add .
git commit -m "descriptive commit message"
# Note: This is an audit codebase, so follow audit-specific branching if applicable
```

## Special Considerations for Audit Codebase

### This is an Educational Audit Project
- **Do NOT fix vulnerabilities** unless specifically asked to do so
- **Document findings** rather than automatically fixing them
- **Preserve intentional vulnerabilities** for learning purposes
- **Focus on analysis and reporting** rather than remediation

### Testing Strategy
- Ensure existing tests continue to pass
- Add tests for new functionality but be careful not to "fix" intentional vulnerabilities
- Use tests to demonstrate vulnerabilities rather than prevent them

### Version Considerations
- Solidity ^0.7.6 lacks automatic overflow protection
- OpenZeppelin v3.4.0 may have different APIs than newer versions
- Be mindful of legacy patterns and security considerations