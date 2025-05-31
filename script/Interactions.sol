// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        return createSubscription(config.vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64) {
        vm.startBroadcast();
        uint64 subId = uint64(VRFCoordinatorV2Mock(vrfCoordinator).createSubscription());
        vm.stopBroadcast();
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        fundSubscription(config.vrfCoordinator, config.subscriptionId);
    }

    function fundSubscription(address vrfCoordinator, uint64 subscriptionId) public {
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subscriptionId, 3 ether);
        vm.stopBroadcast();
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        addConsumer(raffle, config.vrfCoordinator, config.subscriptionId);
    }

    function addConsumer(address raffle, address vrfCoordinator, uint64 subscriptionId) public {
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subscriptionId, raffle);
        vm.stopBroadcast();
    }

    function run() external {
        address raffle = address(0x123); // This should be replaced with the actual raffle address
        addConsumerUsingConfig(raffle);
    }
}