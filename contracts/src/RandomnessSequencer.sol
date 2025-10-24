// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {RLPTxBreakdown} from "./RLP/RLPTxBreakdown.sol";
import {ISequencingChain} from "./interfaces/ISequencingChain.sol";

contract RandomnessSequencer is AccessControl, ISequencingChain {
    bytes32 public constant RANDOM_ADMIN_ROLE = keccak256("RANDOM_ADMIN_ROLE");
    bytes32 public constant SEQUENCER_ADMIN_ROLE = keccak256("SEQUENCER_ADMIN_ROLE");
    bytes32 public constant FUNCTION_SELECTOR_ADMIN_ROLE = keccak256("FUNCTION_SELECTOR_ADMIN_ROLE");

    ISequencingChain public sequencingAddress;

    bytes[] public mempool;
    mapping(address contractAddress => mapping(address playerAddress => mapping(bytes4 selector => uint256 nonce)))
        public transactionNonces;

    // Track contract address + function signature combinations that should be held for randomness
    struct ContractFunction {
        address contractAddress;
        bytes4 selector;
    }

    ContractFunction[] public randomnessRequiredFunctions;
    mapping(address contractAddress => mapping(bytes4 selector => bool)) public isRandomnessRequired;

    event MempoolUpdated(uint256 mempoolSize, bytes txn);
    event MempoolCleared();
    event FunctionSelectorAdded(address indexed contractAddress, bytes4 indexed selector);
    event FunctionSelectorRemoved(address indexed contractAddress, bytes4 indexed selector);

    constructor(
        address sequencingAddress_,
        address randomnessRole_,
        address sequencerRole_,
        address functionSelectorAdminRole_,
        address adminRole_
    ) {
        sequencingAddress = ISequencingChain(sequencingAddress_);
        _grantRole(RANDOM_ADMIN_ROLE, randomnessRole_);
        _grantRole(SEQUENCER_ADMIN_ROLE, sequencerRole_);
        _grantRole(FUNCTION_SELECTOR_ADMIN_ROLE, functionSelectorAdminRole_);
        _grantRole(DEFAULT_ADMIN_ROLE, adminRole_);
    }

    function addToFunctionAllowlist(address contractAddress, bytes4 selector)
        external
        onlyRole(FUNCTION_SELECTOR_ADMIN_ROLE)
    {
        require(!isRandomnessRequired[contractAddress][selector], "Function already added");
        randomnessRequiredFunctions.push(ContractFunction({contractAddress: contractAddress, selector: selector}));
        isRandomnessRequired[contractAddress][selector] = true;
        emit FunctionSelectorAdded(contractAddress, selector);
    }

    function removeFromFunctionAllowlist(address contractAddress, bytes4 selector)
        external
        onlyRole(FUNCTION_SELECTOR_ADMIN_ROLE)
    {
        require(isRandomnessRequired[contractAddress][selector], "Function not found");

        // Find and remove from array
        for (uint256 i = 0; i < randomnessRequiredFunctions.length; i++) {
            if (
                randomnessRequiredFunctions[i].contractAddress == contractAddress
                    && randomnessRequiredFunctions[i].selector == selector
            ) {
                randomnessRequiredFunctions[i] = randomnessRequiredFunctions[randomnessRequiredFunctions.length - 1];
                randomnessRequiredFunctions.pop();
                break;
            }
        }

        isRandomnessRequired[contractAddress][selector] = false;
        emit FunctionSelectorRemoved(contractAddress, selector);
    }

    function getAllowlistedFunctions() external view returns (ContractFunction[] memory) {
        return randomnessRequiredFunctions;
    }

    function processRandomTransaction(bytes calldata randomTransaction) external onlyRole(RANDOM_ADMIN_ROLE) {
        sequencingAddress.processTransaction(randomTransaction);

        if (mempool.length != 0) {
            sequencingAddress.processTransactionsBulk(mempool);
            delete mempool;
            emit MempoolCleared();
        }
    }

    function getFunctionSelector(bytes memory data) internal pure returns (bytes4 selector) {
        require(data.length >= 4, "Data too short");
        assembly {
            selector := mload(add(data, 32))
        }
        return selector;
    }

    function processTransactionsBulk(bytes[] calldata txns) external override onlyRole(SEQUENCER_ADMIN_ROLE) {
        _processTransactionsBulk(txns);
    }

    function _processTransactionsBulk(bytes[] memory txns) internal {
        for (uint256 i = 0; i < txns.length; i++) {
            _processTransaction(txns[i]);
        }
    }

    function processTransaction(bytes calldata txn) public override onlyRole(SEQUENCER_ADMIN_ROLE) {
        _processTransaction(txn);
    }

    function _processTransaction(bytes memory txn) internal {
        RLPTxBreakdown.DecodedTransaction memory decodedTx = RLPTxBreakdown.decodeTx(txn);
        // Skip function selector checking for contract deployments (to == address(0))
        if (decodedTx.data.length > 0 && decodedTx.to != address(0)) {
            bytes4 selector = getFunctionSelector(decodedTx.data);
            if (isRandomnessRequired[decodedTx.to][selector]) {
                transactionNonces[decodedTx.to][decodedTx.from][selector]++;
                mempool.push(txn);
                emit MempoolUpdated(mempool.length, txn);
                return;
            }
        }
        sequencingAddress.processTransaction(txn);
    }

    function getMempoolLength() external view returns (uint256) {
        return mempool.length;
    }
}
