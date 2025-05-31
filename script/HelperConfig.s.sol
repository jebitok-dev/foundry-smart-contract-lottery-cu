// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {LinkToken} from "../test/mocks/LinkToken.sol";
import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    
    error HelperConfig__InvalidChainId();

    uint256 constant DEFAULT_ANVIL_KEY = uint256(uint160(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));

    struct NetworkConfig {
        uint64 subscriptionId;
        bytes32 gasLane;
        uint256 interval;
        uint256 entranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinator;
        address linkToken;
        uint256 deployerKey;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Local network state variables
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() {
        if (block.chainid == 11155111) {
            localNetworkConfig = getSepoliaEthConfig();
        } else {
            localNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    /**
    * modifier onlyValidConsumer(uint64 _subId, address _consumer) {
    *    if (!consumerIsAdded(_subId, _consumer)) {
    *        revert InvalidConsumer();
    *    }
    *    _;
    * } 
    */

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(
        uint256 chainId,
        NetworkConfig memory networkConfig
    ) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getMainnetEthConfig()
        public
        pure
        returns (NetworkConfig memory mainnetNetworkConfig)
    {
        mainnetNetworkConfig = NetworkConfig({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805,
            interval: 30, // 30 seconds
            entranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            linkToken: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            deployerKey: 0
        });
    }

    function getSepoliaEthConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        return NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500_000, // 500,000 gas
            subscriptionId: 1, // Using a smaller value for testing
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY")
        });
    }

    function getLocalConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: address(0),
            gasLane: "",
            callbackGasLimit: 500000,
            subscriptionId: 0,
            linkToken: address(0),
            deployerKey: 0
        });
    }

    function getOrCreateAnvilEthConfig() internal returns (NetworkConfig memory) {
        // Check to see if we set an active network localNetworkConfig
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        console2.log(unicode"⚠️ You have deployed a mock contract!");
        console2.log("Make sure this was intentional");

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK
        );
        LinkToken linkToken = new LinkToken();
        uint64 subscriptionId = uint64(vrfCoordinatorMock.createSubscription());
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            callbackGasLimit: 500000, // 500,000 gas
            subscriptionId: subscriptionId,
            linkToken: address(linkToken),
            deployerKey: DEFAULT_ANVIL_KEY
        });

        return localNetworkConfig;
    }
}
