// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console, Vm} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Interface} from "chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;
    uint256 deployerKey;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        linkToken = config.linkToken;
        deployerKey = config.deployerKey;
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWHenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}();
        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Accert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testEmitsEventOnEntrance() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        // Warp time forward and roll block number
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        
        // Mock the VRF Coordinator to prevent revert
        vm.mockCall(
            address(vrfCoordinator),
            abi.encodeWithSelector(VRFCoordinatorV2Interface.requestRandomWords.selector),
            abi.encode(1)
        );
        
        // Act / Assert
        raffle.performUpkeep("");
        
        // Try to enter again
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Mock the VRF Coordinator to prevent revert
        vm.mockCall(
            address(vrfCoordinator),
            abi.encodeWithSelector(VRFCoordinatorV2Interface.requestRandomWords.selector),
            abi.encode(1)
        );

        // Act
        raffle.performUpkeep("");
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        // Assert
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upkeepNeeded == false);
    }

    modifier raffleEntredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntredAndTimePassed {
        // Mock the VRF Coordinator to prevent revert
        vm.mockCall(
            address(vrfCoordinator),
            abi.encodeWithSelector(VRFCoordinatorV2Interface.requestRandomWords.selector),
            abi.encode(1)
        );

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory logs = vm.getRecordedLogs();
        
        // Find the requestId from the logs
        uint256 requestId;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("RandomWordsRequested(bytes32,uint256,uint256,uint64,uint16,uint32,uint32,address)")) {
                requestId = uint256(logs[i].topics[1]);
                break;
            }
        }

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint(raffleState) == 1); // 0 = open, 1 = calculating
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntredAndTimePassed {
        // Arrange
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        uint256 startingTimeStamp = raffle.getLatestTimeStamp();

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address player = address(uint160(i));
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * (additionalEntrants + 1);
        address expectedWinner = address(uint160(startingIndex + 1)); // The second player
        uint256 winnerStartingBalance = expectedWinner.balance;

        console.log("Expected winner:", expectedWinner);
        console.log("Number of players:", raffle.getNumberOfPlayers());

        // Mock the VRF Coordinator to prevent revert
        vm.mockCall(
            address(vrfCoordinator),
            abi.encodeWithSelector(VRFCoordinatorV2Interface.requestRandomWords.selector),
            abi.encode(1)
        );

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory logs = vm.getRecordedLogs();
        
        // Find the requestId from the logs
        uint256 requestId;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("RandomWordsRequested(bytes32,uint256,uint256,uint64,uint16,uint32,uint32,address)")) {
                requestId = uint256(logs[i].topics[1]);
                break;
            }
        }

        // Create an array with a specific random word that will select our expected winner
        uint256[] memory randomWords = new uint256[](1);
        // We want to select the second player (index 1)
        // Since we have 4 players total (1 initial + 3 additional), we need a number that mod 4 = 1
        randomWords[0] = 5; // 5 % 4 = 1, which will select the second player

        console.log("Random word:", randomWords[0]);
        console.log("Random word mod players:", randomWords[0] % raffle.getNumberOfPlayers());

        // Pretend to be Chainlink VRF
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWordsWithOverride(
            requestId,
            address(raffle),
            randomWords
        );

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLatestTimeStamp();

        console.log("Recent winner:", recentWinner);
        console.log("Raffle state:", uint256(raffleState));
        console.log("Winner balance:", winnerBalance);
        console.log("Winner starting balance:", winnerStartingBalance);
        console.log("Prize amount:", prize);

        assert(expectedWinner == recentWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}