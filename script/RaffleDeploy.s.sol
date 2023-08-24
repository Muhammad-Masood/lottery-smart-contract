//SPDX-License-Identifier:MIT
pragma solidity 0.8.21;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Subscription} from "./Interactions.s.sol";

contract RaffleDeployScript is Script {

    function run() external returns (Raffle) {
        uint256 lotteryTicket = 0.1 ether;
        // @dev lottery will be drawn every week. Conversion of 7 days into milliseconds.
        uint256 duration = 604800000;
        uint64 subscriptionId = 4709;

        vm.startBroadcast();
        HelperConfig helperConfig = new HelperConfig();
        (address vrfCoordinatorAddress, bytes32 keyHash, address linkToken) = helperConfig
            .getNetworkConfig();
        Raffle raffle = new Raffle(
            lotteryTicket,
            duration,
            vrfCoordinatorAddress,
            keyHash,
            subscriptionId
        );

        if(subscriptionId == 0){
        Subscription subscription = new Subscription();
        subscriptionId = subscription.createSubscription(vrfCoordinatorAdress);
        subscription.fundSubscription(vrfCoordinatorAdress,linkToken,subscriptionId);
        }
        vm.stopBroadcast();

        // add consumer -> RAFFLE contract

        uint64 subscriptionId = new CreateSubscription();
        console.log("Subscription ID: ", subscriptionId);   

        console.log("Contract deployed to ", address(raffle));
        console.log("Vrf Coordinator: ", vrfCoordinatorAddress);
        return raffle;
    }
}
