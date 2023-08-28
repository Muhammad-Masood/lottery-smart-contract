// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 keyHash;
        address linkToken;
        uint64 subscriptionId;
        uint256 deployerKey;
    }

    uint256 public constant DEFAULT_ANVIL_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

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
        s_networkConfig = NetworkConfig(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            0x779877A7B0D9E8603169DdbD7836e478b4624789,
            4770,
            vm.envUint("PRIVATE_KEY")
        );
    }

    function setEthereumHelperConfig() internal {
        s_networkConfig = NetworkConfig(
            0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef,
            0x514910771AF9Ca656af840dff83E8264EcF986CA,
            0,
            vm.envUint("PRIVATE_KEY")
        );
    }

    function setAnvilHelperConfig() internal {
        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        s_networkConfig = NetworkConfig(
            address(vrfCoordinator),
            0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef,
            address(0),
            0,
            DEFAULT_ANVIL_KEY
        );
    }

    function getNetworkConfig()
        public
        view
        returns (address, bytes32, address, uint64, uint256)
    {
        return (
            s_networkConfig.vrfCoordinator,
            s_networkConfig.keyHash,
            s_networkConfig.linkToken,
            s_networkConfig.subscriptionId,
            s_networkConfig.deployerKey
        );
    }
}
