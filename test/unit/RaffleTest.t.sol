// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Raffle} from "../../src/Raffle.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {console} from "../../lib/forge-std/src/console.sol";
import {RaffleDeployScript} from "../../script/RaffleDeploy.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {

    event NewParticipant (address indexed participant);

    address private PARTICIPANT = makeAddr("participant");
    address[] private array;
    uint256 private lotteryTicket;
    Raffle private raffle;
    HelperConfig private helperConfig;
    address private vrfCoordinator;
    uint256 constant private STARTING_USER_BALANCE = 1 ether;

    modifier raffleEnterAndTimePassed() {
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:lotteryTicket}();
        vm.warp(block.timestamp+raffle.getRaffleDuration()+1);
        vm.roll(block.timestamp+1);
        _;
    }

    modifier skipFork(){
        if(block.chainid != 31337){
            return;
        }
        _;
    }

    function setUp() external {
        RaffleDeployScript raffleScript = new RaffleDeployScript(); 
        (raffle,helperConfig) = raffleScript.run();
        (vrfCoordinator,,,,) = helperConfig.getNetworkConfig();
        vm.deal(PARTICIPANT,1 ether);
        lotteryTicket = raffle.getLotteryPrice();   
    }

    /////////////////////////
    ///// Enter Raffle /////
    ///////////////////////

    function test_initializeRaffleAsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function test_enterRaffle_invalidAmount() public {
        vm.expectRevert(Raffle.Raffle__UnsufficientFunds.selector);
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:0 ether}();
    }

    function test_enterRaffle_invalidAddress() public {
        vm.expectRevert(Raffle.Raffle_AddressZero.selector);
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
        emit NewParticipant(PARTICIPANT);
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:lotteryTicket}();
    }

    function test_pickWinner_cantEnterWhenRaffleIsClosed() public raffleEnterAndTimePassed {
        raffle.performUpkeep("");
        // vm.expectRevert(Raffle.Raffle__RaffleClosed.selector);
        // vm.prank(PARTICIPANT);
        // raffle.enterRaffle{value:lotteryTicket}();
    }

    /////////////////////////
    ///// Pick Winner //////
    ///////////////////////

    //Check Upkeep

    function testFail_UpkeepFalseIfDurationNotPassed() public {
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:lotteryTicket}();
        console.log(block.timestamp);
        uint256 performUpkeepTime = raffle.getLastTimeStamp() + raffle.getRaffleDuration();
        console.log(performUpkeepTime);
        raffle.performUpkeep("");
    }

    function test_UpkeepFalseIfNotEnoughBalance() public {
        console.log("contract balance: ",address(raffle).balance);
        vm.warp(block.timestamp+raffle.getRaffleDuration()+1);
        vm.roll(block.timestamp+1);
        (bool upKeep,) = raffle.checkUpkeep("");
        assert(!upKeep);
    }

    function test_UpkeepFalseIfStateIsClosed() public raffleEnterAndTimePassed {
        raffle.performUpkeep("");
        (bool checkUpKeep,) = raffle.checkUpkeep("");
        assert(!checkUpKeep);
    }

    // Perform Upkeep

    function test_UpkeepTrueWhenNeeded() external raffleEnterAndTimePassed {
        (bool upKeep,) = raffle.checkUpkeep("");
        assert(upKeep);
    }

    function test_UpkeepRevertWhenNotNeeded() public {
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value:lotteryTicket}();
        // vm.warp(block.timestamp+raffle.getRaffleDuration()+1);
        // vm.roll(block.timestamp+1);
        vm.expectRevert(Raffle.Raffle__UpkeepNotNeeded.selector);
        raffle.performUpkeep("");
    }

    // Get data from an event

    function testPerformUpkeepUpdatesStateAndEmitsRequestId() public raffleEnterAndTimePassed {
        //Act 
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory enteries = vm.getRecordedLogs();
        bytes32 requestId = enteries[1].topics[1];
        console.log("request id: ",uint256(requestId));
        uint16 raffleState = uint16(raffle.getRaffleState());
        assert(raffleState == 1);
        assert(uint256(requestId) > 0);
    }

    // Fulfill Random Words

    // Fuzz testing
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public skipFork {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPickFundWinnerAndReset() public raffleEnterAndTimePassed skipFork {
        uint256 maxPlayers = 10;
        uint256 startingIndex = 1;
        //filling the pariticipants list with players
        for(uint256 i = startingIndex  ; i<maxPlayers+startingIndex; i++){
            address newPlayer = address(uint160(i));
            hoax(newPlayer,STARTING_USER_BALANCE);
            raffle.enterRaffle{value:lotteryTicket}();
        }
        address [] memory participants = raffle.getParticipants();
        //Generating the random winner index
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory enteries = vm.getRecordedLogs();
        bytes32 requestId = enteries[1].topics[1];
        uint256 reqId = uint256(requestId);
        uint256 prize = address(raffle).balance;
        console.log("raffle balance: ",prize);
        vm.recordLogs();
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(reqId,address(raffle));
        Vm.Log[] memory winnerEnteries = vm.getRecordedLogs();
        bytes32 winner = winnerEnteries[0].topics[1];
        address winnerAddress = address(uint160(uint256(winner)));
        console.log("winner address: ", winnerAddress);
        //checking if the winner is from the list of existing players
        bool winnerPresent;
        for(uint256 i = startingIndex ; i<maxPlayers+startingIndex ; i++){
            if(participants[i] == winnerAddress){
                winnerPresent = true;
            }
        }
        uint256 winnerBalance = winnerAddress.balance;
        console.log("winner balance",winnerBalance);

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(winnerPresent);
        assertEq(raffle.getParticipants().length,0);
        assertEq(raffle.getLastTimeStamp(),block.timestamp);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance>=prize);
        assertEq(address(raffle).balance,0);
        assertEq(winnerAddress.balance,(STARTING_USER_BALANCE+prize)-lotteryTicket);
    }

}