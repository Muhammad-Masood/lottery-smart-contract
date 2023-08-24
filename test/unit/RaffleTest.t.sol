// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Raffle} from "../../src/Raffle.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {console} from "../../lib/forge-std/src/console.sol";
import {RaffleDeployScript} from "../../script/RaffleDeploy.s.sol";

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

    /////////////////////////
    ///// Enter Raffle /////
    ///////////////////////

    function test_initializeRaffleAsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testFail_enterRaffle_invalidAmount() public {
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:0 ether}();
    }

    function testFail_enterRaffle_invalidAddress() public {
        hoax(address(0),1 ether);
        raffle.enterRaffle{value:lotteryTicket}();
    }

    // should add the participant to the participants list
    
    function test_enterRaffle_addParticipant() public {
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
        //testing event, when a player enters
        vm.expectEmit(true,false,false,false,address(raffle));
        emit newParticipant(PARTICIPANT);
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:lotteryTicket}();
    }

    /////////////////////////
    ///// Pick Winner //////
    ///////////////////////

    function test_pickWinner_cantEnterWhenRaffleIsClosed() public {
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:lotteryTicket}();
        vm.warp(block.timestamp+raffle.getRaffleDuration()+1);
        vm.roll(block.timestamp+1);
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleClosed.selector);
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:lotteryTicket}();
    }

    function test_pickWinner_upkeepNeeded() public view {
        uint256 drawTime = raffle.getLastTimeStamp() + raffle.getRaffleDuration();
        assert(block.timestamp>=drawTime);
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);

    }

    function test_pickWinner() public view {
        // console.log(raffle.pickWinner());
    }
}