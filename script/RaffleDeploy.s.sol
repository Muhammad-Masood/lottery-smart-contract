//SPDX-License-Identifier:MIT
pragma solidity 0.8.21;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract RaffleDeployScript is Script {
    function run() external returns (Raffle, HelperConfig) {
        uint256 lotteryTicket = 0.01 ether;
        // @dev lottery will be drawn every week. Conversion of 7 days into milliseconds.
        uint256 duration = 259200; //3 days -> seconds

        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinatorAddress,
            bytes32 keyHash,
            address linkToken,
            uint64 subscriptionId,
            uint256 deployerKey
        ) = helperConfig.getNetworkConfig();

        if (subscriptionId == 0) {
            //if subscription isn't created, we will create one
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinatorAddress,
                deployerKey
            );
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinatorAddress,
                subscriptionId,
                linkToken,
                deployerKey
            );

        } else {
            //if already created, we will fund it!
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinatorAddress,
                subscriptionId,
                linkToken,
                deployerKey
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            lotteryTicket,
            duration,
            vrfCoordinatorAddress,
            keyHash,
            subscriptionId
        );

        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            subscriptionId,
            vrfCoordinatorAddress,
            address(raffle),
            deployerKey
        );

        // add consumer -> RAFFLE contract
        console.log("Link Token: ", linkToken);
        console.log("Contract deployed to ", address(raffle));
        console.log("Vrf Coordinator: ", vrfCoordinatorAddress);
        return (raffle, helperConfig);
    }
}
