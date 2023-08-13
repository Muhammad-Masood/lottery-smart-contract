//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Lottery smart contract
 * @author Muhammad Masood
 * @notice Using Chainlink oracle to get real random winner, and automate.
 */
 
contract Raffle {

    error Raffle__UnsufficientFunds();
    error Raffle_AddressZero();

    enum RaffleState {
        OPEN,
        CLOSED
    }

    uint256 private s_lotteryInterval;
    uint256 private immutable i_lotteryPrice;
    RaffleState private raffleState;

    address [] private s_participants;

    event newParticipant (address indexed participant);

    constructor(uint256 _lotteryPrice, uint256 _interval) {
        i_lotteryPrice = _lotteryPrice;
        s_lotteryInterval = _interval;
    }

    function enterRaffle() external payable {
        if(msg.sender == address(0)) revert Raffle_AddressZero();
        if(msg.value<i_lotteryPrice) revert Raffle__UnsufficientFunds();
        s_participants.push(msg.sender);
        emit newParticipant(msg.sender);
    }

    // Returns the index of the winner [participant] 
    function pickWinner() public view returns (uint256){
        
    }

    function getLotteryPrice() public view returns(uint256){
        return i_lotteryPrice;
    }

    function getParticipants() public view returns (address [] memory){
        return s_participants;
    }
}