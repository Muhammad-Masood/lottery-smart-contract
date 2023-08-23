// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script {

    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 keyHash;
    }

    NetworkConfig private s_networkConfig;

    constructor() {
        setNetworkConfig();
    }

    function setNetworkConfig() public {
        if (block.chainid == 11155111) {
            setSepliaHelperConfig();
        } else if (block.chainid == 1) {
            setEthereumHelperConfig();
        } else if (block.chainid == 31337) {
            setAnvilHelperConfig();
        }
    }

    function setSepliaHelperConfig() internal {
        s_networkConfig = NetworkConfig(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c);
    }

    function setEthereumHelperConfig() internal {
        s_networkConfig = NetworkConfig(0x271682DEB8C4E0901D1a1550aD2e64D568E69909,0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef);
    }

    function setAnvilHelperConfig() internal {
        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;
        
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(baseFee,gasPriceLink);
        vm.stopBroadcast();
        s_networkConfig = NetworkConfig(address(vrfCoordinator),0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef);   
    }

    function getNetworkConfig() public view returns(NetworkConfig memory){
        return s_networkConfig;
    }

}
