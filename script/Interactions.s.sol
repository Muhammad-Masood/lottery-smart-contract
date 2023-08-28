// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {console} from "forge-std/console.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        (address _vrfCoordinator, , , , uint256 deployerKey) = helperConfig
            .getNetworkConfig();
        createSubscription(_vrfCoordinator, deployerKey);
    }

    function createSubscription(
        address _vrfCoordinator,
        uint256 _deployerKey
    ) public returns (uint64) {
        vm.startBroadcast(_deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Subscription ID: ", subId);
        return subId;
    }
}

contract FundSubscription is Script {
    uint96 private constant FUND_AMOUNT = 1 ether; // 3 Links

    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        (
            address _vrfCoordinator,
            ,
            address linkToken,
            uint64 subscriptionId,
            uint256 deployerKey
        ) = helperConfig.getNetworkConfig();
        fundSubscription(
            _vrfCoordinator,
            subscriptionId,
            linkToken,
            deployerKey
        );
    }

    function fundSubscription(
        address _vrfCoordinator,
        uint64 _subId,
        address linkToken,
        uint256 _deployerKey
    ) public {
        if (block.chainid == 31337) {
            vm.startBroadcast(_deployerKey);
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(
                _subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            console.log(
                "User Link  Token Balance: ",
                LinkToken(linkToken).balanceOf(msg.sender)
            );
            vm.startBroadcast(_deployerKey);
            LinkToken(linkToken).transferAndCall(
                _vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(_subId)
            );
            vm.stopBroadcast();
            console.log(
                "User Link  Token Balance: ",
                LinkToken(linkToken).balanceOf(msg.sender)
            );
        }
    }
}

contract AddConsumer is Script {
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinator,
            ,
            ,
            uint64 subscriptionId,
            uint256 deployerKey
        ) = helperConfig.getNetworkConfig();
        //using foundry devOps to get the most recent deployed contract
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        console.log(raffle);
        addConsumer(subscriptionId, vrfCoordinator, raffle, deployerKey);
    }

    function addConsumer(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _consumer,
        uint256 _deployerKey
    ) public {
        vm.startBroadcast(_deployerKey);
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(
            _subscriptionId,
            _consumer
        );
        vm.stopBroadcast();
    }
}
