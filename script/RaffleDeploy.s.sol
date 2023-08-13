//SPDX-License-Identifier:MIT
pragma solidity 0.8.21;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "forge-std/console.sol";

contract RaffleDeployScript is Script {
    
    Raffle private raffle;
    uint256 private lotteryTicket = 0.1 ether;
    uint256 private interval = 1692551628; 

    function run() external returns (Raffle) {
        vm.startBroadcast();
        raffle = new Raffle(lotteryTicket,interval);
        vm.stopBroadcast();
        console.log('Contract deployed to ', address(raffle));
        return raffle;
    }

}