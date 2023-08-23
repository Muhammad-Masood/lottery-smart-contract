// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Raffle} from "../src/Raffle.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {RaffleDeployScript} from "../script/RaffleDeploy.s.sol";

contract RaffleTest is Test {

    event newParticipant(address indexed participant);
    address private PARTICIPANT = makeAddr("participant");
    address[] private array;
    uint256 private lotteryTicket;
    Raffle private raffle;

    function setUp() external {
        RaffleDeployScript raffleScript = new RaffleDeployScript(); 
        raffle = raffleScript.run();
        vm.deal(PARTICIPANT,1 ether);
        lotteryTicket = raffle.getLotteryPrice();   
    }

    function testFail_enterRaffle_invalidAmount() public {
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:0 ether}();
    }

    function test_enterRaffle() public {
        address [] memory participants = raffle.getParticipants();
        uint256 numOfParticipants = participants.length;
        console.log(numOfParticipants);
        assertEq(numOfParticipants,0);
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:lotteryTicket}();
        assertEq((raffle.getParticipants()).length,++numOfParticipants);
        participants = raffle.getParticipants();
        address newPlayer = participants[0];
        assertEq(PARTICIPANT,newPlayer);
        vm.expectEmit(true,false,false,false,address(raffle));
        emit newParticipant(PARTICIPANT);
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:lotteryTicket}();
    }

    function test_pickWinner() public view {
        // console.log(raffle.pickWinner());
    }
}