// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ISequencingChain {
    function processTransaction(bytes calldata data) external;
    function processTransactionsBulk(bytes[] calldata data) external;
}
