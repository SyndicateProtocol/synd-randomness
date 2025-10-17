// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {RandomnessSequencer} from "../src/RandomnessSequencer.sol";
import {Random} from "../src/Random.sol";
import {console} from "forge-std/console.sol";

contract DeployRandomnessSequencer is Script {
    function run() external returns (RandomnessSequencer) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address sequencingAddress = vm.envAddress("SEQUENCING_ADDRESS");
        address randomnessRole = vm.envAddress("RANDOMNESS_ROLE");
        address sequencerRole = vm.envAddress("SEQUENCER_ROLE");
        address functionSelectorAdminRole = vm.envAddress("FUNCTION_SELECTOR_ADMIN_ROLE");
        address adminRole = vm.envAddress("ADMIN_ROLE");

        vm.startBroadcast(deployerPrivateKey);

        RandomnessSequencer sequencer = new RandomnessSequencer(
            sequencingAddress, randomnessRole, sequencerRole, functionSelectorAdminRole, adminRole
        );
        console.log("RandomnessSequencer deployed to:", address(sequencer));
        console.log("SequencingAddress:", sequencingAddress);
        console.log("RandomnessRole:", randomnessRole);
        console.log("SequencerRole:", sequencerRole);
        console.log("FunctionSelectorAdminRole:", functionSelectorAdminRole);
        console.log("AdminRole:", adminRole);

        vm.stopBroadcast();
        return sequencer;
    }
}

contract DeployRandom is Script {
    function run() external returns (Random) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address randomnessAdmin = vm.envAddress("RANDOMNESS_ADMIN");
        vm.startBroadcast(deployerPrivateKey);
        Random random = new Random(randomnessAdmin);

        console.log("Random deployed to:", address(random));
        console.log("RandomnessAdmin:", randomnessAdmin);

        vm.stopBroadcast();
        return random;
    }
}
