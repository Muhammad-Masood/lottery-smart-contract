//SPDX-License-Identifier:MIT
pragma solidity 0.8.21;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract RaffleDeployScript is Script {
    
    Raffle private raffle;
    uint256 private lotteryTicket = 0.1 ether;
    // @dev lottery will be drawn every week. Conversion of 7 days into milliseconds.
    uint256 private duration = 604800000;  
    uint64 private subscriptionId = 4709;
    // address private vrfCoordinatorAddress;
    // bytes32 private keyHash;

    function run() external returns (Raffle) {
        vm.startBroadcast();
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig;
        networkConfig = helperConfig.getNetworkConfig();
        raffle = new Raffle(lotteryTicket,duration,networkConfig.vrfCoordinator,networkConfig.keyHash,subscriptionId);
        vm.stopBroadcast();
        console.log('Contract deployed to ', address(raffle));
        return raffle;
    }

}