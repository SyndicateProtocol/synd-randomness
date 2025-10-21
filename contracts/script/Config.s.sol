// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {RandomnessSequencer} from "../src/RandomnessSequencer.sol";
import {Random} from "../src/Random.sol";
import {IAllowlistSequencingModule} from "../src/interfaces/IAllowlistSequencingModule.sol";
import {console} from "forge-std/console.sol";

contract AddFunctionToRandomnessSequencerAllowlist is Script {
    function run() external {
        address randomnessSequencerContractAddress = vm.envAddress("RANDOMNESS_SEQUENCER_CONTRACT_ADDRESS");
        uint256 functionSelectorAdminPrivateKey = vm.envUint("FUNCTION_SELECTOR_ADMIN_PRIVATE_KEY");
        address targetContractAddress = vm.envAddress("TARGET_CONTRACT_ADDRESS");
        string memory targetFunctionSignature = vm.envString("TARGET_FUNCTION_SIGNATURE");

        bytes4 functionSelector = bytes4(keccak256(bytes(targetFunctionSignature)));

        vm.startBroadcast(functionSelectorAdminPrivateKey);

        RandomnessSequencer(randomnessSequencerContractAddress)
            .addToFunctionAllowlist(targetContractAddress, functionSelector);
        console.log("Target contract address:", targetContractAddress);
        console.log("Target function signature:", targetFunctionSignature);
        console.log("Function selector:", vm.toString(functionSelector));
        vm.stopBroadcast();
    }
}

contract AllowlistRandomnessSequencerOnSyndicateSequencingChain is Script {
    function run() external {
        uint256 allowlistPermissionModuleOwnerPrivateKey = vm.envUint("ALLOWLIST_PERMISSION_MODULE_OWNER_PRIVATE_KEY");
        address allowlistPermissionModuleAddress = vm.envAddress("ALLOWLIST_PERMISSION_MODULE_ADDRESS");
        address randomnessSequencerContractAddress = vm.envAddress("RANDOMNESS_SEQUENCER_CONTRACT_ADDRESS");
        vm.startBroadcast(allowlistPermissionModuleOwnerPrivateKey);
        IAllowlistSequencingModule(allowlistPermissionModuleAddress).addToAllowlist(randomnessSequencerContractAddress);
        vm.stopBroadcast();
    }
}

contract AddRandomAdminToRandomnessSequencer is Script {
    function run() external {
        uint256 randomnessSequencerDefaultAdminPrivateKey = vm.envUint("RANDOMNESS_SEQUENCER_DEFAULT_ADMIN_PRIVATE_KEY");
        address randomnessSequencerContractAddress = vm.envAddress("RANDOMNESS_SEQUENCER_CONTRACT_ADDRESS");
        address randomAdmin = vm.envAddress("RANDOM_ADMIN");
        vm.startBroadcast(randomnessSequencerDefaultAdminPrivateKey);
        RandomnessSequencer randomnessSequencer = RandomnessSequencer(randomnessSequencerContractAddress);
        randomnessSequencer.grantRole(randomnessSequencer.RANDOM_ADMIN_ROLE(), randomAdmin);
        console.log("Random admin:", randomAdmin);
        console.log("Randomness sequencer contract address:", randomnessSequencerContractAddress);
        vm.stopBroadcast();
    }
}

contract AddRandomAdminToRandom is Script {
    function run() external {
        uint256 randomDefaultAdminPrivateKey = vm.envUint("RANDOM_DEFAULT_ADMIN_PRIVATE_KEY");
        address randomContractAddress = vm.envAddress("RANDOM_CONTRACT_ADDRESS");
        address randomAdmin = vm.envAddress("RANDOM_ADMIN");
        vm.startBroadcast(randomDefaultAdminPrivateKey);
        Random random = Random(randomContractAddress);
        random.grantRole(random.RANDOM_ADMIN_ROLE(), randomAdmin);
        console.log("Random admin:", randomAdmin);
        console.log("Random contract address:", randomContractAddress);
        vm.stopBroadcast();
    }
}
