// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {RandomnessSequencer} from "../src/RandomnessSequencer.sol";
import {Random} from "../src/Random.sol";
import {DoSomethingWithRandom} from "../src/DoSomethingWithRandom.sol";
import {console} from "forge-std/console.sol";

contract DeployRandomnessSequencer is Script {
    function run() external returns (RandomnessSequencer) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address sequencingContractAddress = vm.envAddress("SEQUENCING_CONTRACT_ADDRESS");
        address randomAdmin = vm.envAddress("RANDOM_ADMIN");
        address sequencerAdmin = vm.envAddress("SEQUENCER_ADMIN");
        address functionSelectorAdmin = vm.envAddress("FUNCTION_SELECTOR_ADMIN");
        address admin = vm.envAddress("RANDOMNESS_SEQUENCER_DEFAULT_ADMIN");

        vm.startBroadcast(deployerPrivateKey);

        RandomnessSequencer sequencer = new RandomnessSequencer(
            sequencingContractAddress, randomAdmin, sequencerAdmin, functionSelectorAdmin, admin
        );
        console.log("RandomnessSequencer deployed to:", address(sequencer));
        console.log("Syndicate Sequencing Contract Address:", sequencingContractAddress);
        console.log("Random admin:", randomAdmin);
        console.log("Sequencer admin:", sequencerAdmin);
        console.log("Function Selector admin:", functionSelectorAdmin);
        console.log("Default admin:", admin);

        vm.stopBroadcast();
        return sequencer;
    }
}

contract DeployRandom is Script {
    function run() external returns (Random) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address randomAdmin = vm.envAddress("RANDOM_ADMIN");
        address admin = vm.envAddress("RANDOM_DEFAULT_ADMIN");
        vm.startBroadcast(deployerPrivateKey);
        Random random = new Random(randomAdmin, admin);

        console.log("Random deployed to:", address(random));
        console.log("Random default admin:", randomAdmin);
        console.log("Admin:", admin);

        vm.stopBroadcast();
        return random;
    }
}

contract DeployDoSomethingWithRandom is Script {
    function run() external returns (DoSomethingWithRandom) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address randomContractAddress = vm.envAddress("RANDOM_CONTRACT_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);
        DoSomethingWithRandom doSomethingWithRandom = new DoSomethingWithRandom(randomContractAddress);
        console.log("DoSomethingWithRandom deployed to:", address(doSomethingWithRandom));
        console.log("Random Contract Address:", randomContractAddress);
        vm.stopBroadcast();
        return doSomethingWithRandom;
    }
}
