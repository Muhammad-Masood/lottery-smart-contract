//SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Lottery smart contract
 * @author Muhammad Masood
 * @notice Using Chainlink oracle to get real random winner, and automate the lotetery.
 */

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2{

    error Raffle__UnsufficientFunds();
    error Raffle_AddressZero();
    error Raffle_DurationNotPassed();
    error Raffle__WinnerTransferFailed();
    error Raffle__RaffleClosed();
    error Raffle__UpkeepNotNeeded();

    enum RaffleState {
        OPEN,
        CLOSED
    }

    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant REQUEST_CONFIRMATIONS = 1;
    uint32 private constant NUM_WORDS = 32;

    // @dev duration of the lottery
    uint256 private immutable i_lotteryDuration; 
    uint256 private immutable i_lotteryPrice;
    bytes32 private immutable i_keyHash; // @dev gas lane
    uint64 private immutable i_subscriptionId;
    VRFCoordinatorV2Interface private immutable i_VRFCoordinator;

    uint256 private s_lastTimestamp;
    RaffleState private s_raffleState;

    address [] private s_participants;

    event NewParticipant (address indexed participant);
    event WinnerPicked (address indexed winner);

    constructor(uint256 _lotteryPrice, uint256 _duration, 
    address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId) VRFConsumerBaseV2(_vrfCoordinator) {
        i_lotteryPrice = _lotteryPrice;
        s_lastTimestamp = block.timestamp;
        i_lotteryDuration = _duration;
        i_VRFCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if(msg.sender == address(0)) revert Raffle_AddressZero();
        if(msg.value<i_lotteryPrice) revert Raffle__UnsufficientFunds();
        if(s_raffleState != RaffleState.OPEN) revert Raffle__RaffleClosed();
        s_participants.push(msg.sender);
        emit NewParticipant(msg.sender);
    }

    /**
     * @dev Chainlink Automation nodes will call this function
     * to see if its time to perform the upkeep. We'll be writing oour cutom logic
     * which we want to be satisfied to trigger the function (aka pickWinner).
     * following should be true for this function to return true
     * 1. The time interval has passed 
     * 2. Raffle is in the OPEN state
     * 3. Contract has some players/eth
     * 4. The Subscription is funded with Link (Implicit)
     */

    function checkUpkeep(bytes memory /* checkData */) public view
        returns (bool upkeepNeeded, bytes memory performData) {
            bool timePassed = (block.timestamp > s_lastTimestamp + i_lotteryDuration);
            bool isOpen = (s_raffleState == RaffleState.OPEN);
            bool hasParticipants = (s_participants.length > 0);
            bool hasBalance = (address(this).balance > 0);
            upkeepNeeded = (timePassed && isOpen && hasParticipants && hasBalance);
            return (upkeepNeeded,"0x0");
        }

    // Returns the index of the winner [participant] 
     function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded) revert Raffle__UpkeepNotNeeded();
        // if(!upkeepNeeded) revert Raffle__UnsufficientFunds();
        // if(!(block.timestamp > s_lastTimestamp + i_lotteryDuration)) revert Raffle_DurationNotPassed();
        s_raffleState = RaffleState.CLOSED;
        i_VRFCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
    }
    
    function fulfillRandomWords(
        uint256 /**_requestId */, 
        uint256[] memory _randomWords
    ) internal override {
       uint256 winnerIndex = _randomWords[0] % s_participants.length;
       address payable winner = payable(s_participants[winnerIndex]);
       emit WinnerPicked(winner);
       s_participants = new address payable[](0);
       s_lastTimestamp = block.timestamp;
       s_raffleState = RaffleState.OPEN;
       (bool success,) = winner.call{value:address(this).balance}("");
       if(!success) revert Raffle__WinnerTransferFailed();
    }

    function getLotteryPrice() public view returns(uint256){
        return i_lotteryPrice;
    }

    function getParticipants() public view returns (address [] memory){
        return s_participants;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getRaffleDuration() public view returns (uint256) {
        return i_lotteryDuration;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimestamp;
    }
}