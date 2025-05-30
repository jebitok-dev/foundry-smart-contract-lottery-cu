// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {VRFCoordinatorV2Interface} from "chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

import {VRFConsumerBaseV2} from "chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";

import {AutomationCompatibleInterface} from "chainlink/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title A sample Raffle Contract
 * @author Patrick Collins (or even better, you own name)
 * @notice This contract is for creating a sample raffle
 * @dev It implements Chainlink VRFv2.5 and Chainlink Automation
*/

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    // Type declarations
    enum RaffleState {
        OPEN,           // 0
        CALCULATING     // 1
    }

    // Put this one in `Raffle related variables`

    RaffleState private s_raffleState;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    bytes32 private immutable i_gasLane;

    uint64 private immutable i_subscriptionId;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint32 private immutable i_callbackGasLimit;

    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;

    uint256 private immutable i_interval;

    address payable[] private s_players;

    address payable private s_recentWinner;

    uint256 private s_lastTimeStamp;

    event EnteredRaffle(address indexed player);

    event PickedWinner(address winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not Enough ETH sent");
        if(msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();
        if(s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();

        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
    * Get a random number
    * Use the random number to pick a player
    * Automatically called 
    */

    function pickWinner() external {
       // check to see if enough time has passed 
       if (block.timestamp - s_lastTimeStamp < i_interval) revert();

       s_raffleState = RaffleState.CALCULATING;

       /** 
        *    uint256 requestId = COORDINATOR.requestRandomWords(
        *    keyHash,
        *    s_subscriptionId,
        *    requestConfirmations,
        *   callbackGasLimit,
        *   numWords
        */
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success,) = winner.call{value:address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        } 

        emit PickedWinner(winner);
    }

    /**
    * @dev This is the function that the Chainlink Keeper nodes call
    * they look for `upkeepNeeded` to return True.
    * the following should be true for this to return true:
    * 1. The time interval has passed between raffle runs.
    * 2. The lottery is open.
    * 3. The contract has ETH.
    * 4. There are players registered.
    * 5. Implicitly, your subscription is funded with LINK.
    */

    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Automatically called
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            uint64(i_subscriptionId),
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

}