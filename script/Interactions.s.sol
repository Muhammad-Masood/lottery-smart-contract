// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract Subscription is Script {

    // address public immutable vrfCoordinator;
    uint96 private constant FUND_AMOUNT = 3 ether; // 3 Links

    // function run() external returns (HelperConfig){
    //     vm.startBroadcast();
    //     HelperConfig helperConfig = new HelperConfig();
    //     (vrfCoordinator,,) = helperConfig.getNetworkConfig();
    //     vm.stopBroadcast();
    //     return helperConfig;
    // }

    function createSubscription(address _vrfCoordinator) public  returns (uint64) {
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator).createSubscription();
        return subId;
    }

    function fundSubscription(address _vrfCoordinator, address linkToken, uint64 _subId) public {
        if(block.chainid==31337){
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(_subId, FUND_AMOUNT);
        } else {
            LinkToken(linkToken).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subId));
        }
    }

}
