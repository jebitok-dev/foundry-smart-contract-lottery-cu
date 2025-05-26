import {HelperConfig} from "./HelperConfig.s.sol";

function run() external returns (Raffle, HelperConfig) {
    HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
    (
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;

    ) = helperConfig.getConfig();

    vm.startBroadcast();
    Raffle raffle = new Raffle(
        entranceFee,
        interval,
        vrfCoordinator,
        gasLane,
        subscriptionId,
        callbackGasLimit
    )
    vm.stopBroadcast();


    return raffle;

    
}