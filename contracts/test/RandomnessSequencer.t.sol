// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {RandomnessSequencer} from "../src/RandomnessSequencer.sol";
import {ISequencingChain} from "../src/interfaces/ISequencingChain.sol";

contract MockSequencingChain is ISequencingChain {
    bytes[] public processedTransactions;
    bytes[][] public processedBulkTransactions;

    function processTransaction(bytes calldata data) external override {
        processedTransactions.push(data);
    }

    function processTransactionsBulk(bytes[] calldata data) external override {
        processedBulkTransactions.push(data);
    }

    function getProcessedCount() external view returns (uint256) {
        return processedTransactions.length;
    }

    function getProcessedBulkCount() external view returns (uint256) {
        return processedBulkTransactions.length;
    }
}

contract RandomnessSequencerTest is Test {
    RandomnessSequencer public sequencer;
    MockSequencingChain public mockChain;

    address public admin = address(1);
    address public randomnessRole = address(2);
    address public sequencerRole = address(3);
    address public functionSelectorAdmin = address(4);
    address public unauthorized = address(5);

    event MempoolUpdated(uint256 mempoolSize, bytes txn);
    event MempoolCleared();
    event FunctionSelectorAdded(address indexed contractAddress, bytes4 indexed selector);
    event FunctionSelectorRemoved(address indexed contractAddress, bytes4 indexed selector);

    function setUp() public {
        mockChain = new MockSequencingChain();
        sequencer =
            new RandomnessSequencer(address(mockChain), randomnessRole, sequencerRole, functionSelectorAdmin, admin);
    }

    function testConstructor() public view {
        assertEq(address(sequencer.sequencingAddress()), address(mockChain));
        assertTrue(sequencer.hasRole(sequencer.RANDOM_ADMIN_ROLE(), randomnessRole));
        assertTrue(sequencer.hasRole(sequencer.SEQUENCER_ADMIN_ROLE(), sequencerRole));
        assertTrue(sequencer.hasRole(sequencer.FUNCTION_SELECTOR_ADMIN_ROLE(), functionSelectorAdmin));
        assertTrue(sequencer.hasRole(sequencer.DEFAULT_ADMIN_ROLE(), admin));
    }

    function testAddToFunctionAllowlist() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(keccak256("testFunction()"));

        vm.prank(functionSelectorAdmin);
        vm.expectEmit(true, true, false, true);
        emit FunctionSelectorAdded(targetContract, selector);
        sequencer.addToFunctionAllowlist(targetContract, selector);

        assertTrue(sequencer.isRandomnessRequired(targetContract, selector));

        RandomnessSequencer.ContractFunction[] memory funcs = sequencer.getAllowlistedFunctions();
        assertEq(funcs.length, 1);
        assertEq(funcs[0].contractAddress, targetContract);
        assertEq(funcs[0].selector, selector);
    }

    function testAddToFunctionAllowlistUnauthorized() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(keccak256("testFunction()"));

        vm.prank(unauthorized);
        vm.expectRevert();
        sequencer.addToFunctionAllowlist(targetContract, selector);
    }

    function testAddToFunctionAllowlistAlreadyExists() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(keccak256("testFunction()"));

        vm.prank(functionSelectorAdmin);
        sequencer.addToFunctionAllowlist(targetContract, selector);

        vm.prank(functionSelectorAdmin);
        vm.expectRevert("Function already added");
        sequencer.addToFunctionAllowlist(targetContract, selector);
    }

    function testRemoveFromFunctionAllowlist() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(keccak256("testFunction()"));

        vm.prank(functionSelectorAdmin);
        sequencer.addToFunctionAllowlist(targetContract, selector);

        vm.prank(functionSelectorAdmin);
        vm.expectEmit(true, true, false, true);
        emit FunctionSelectorRemoved(targetContract, selector);
        sequencer.removeFromFunctionAllowlist(targetContract, selector);

        assertFalse(sequencer.isRandomnessRequired(targetContract, selector));

        RandomnessSequencer.ContractFunction[] memory funcs = sequencer.getAllowlistedFunctions();
        assertEq(funcs.length, 0);
    }

    function testRemoveFromFunctionAllowlistUnauthorized() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(keccak256("testFunction()"));

        vm.prank(functionSelectorAdmin);
        sequencer.addToFunctionAllowlist(targetContract, selector);

        vm.prank(unauthorized);
        vm.expectRevert();
        sequencer.removeFromFunctionAllowlist(targetContract, selector);
    }

    function testRemoveFromFunctionAllowlistNotFound() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(keccak256("testFunction()"));

        vm.prank(functionSelectorAdmin);
        vm.expectRevert("Function not found");
        sequencer.removeFromFunctionAllowlist(targetContract, selector);
    }

    function testProcessTransactionWithoutRandomnessRequired() public {
        // Create a simple EIP-1559 transaction
        bytes memory txn = _createType2MockTransaction(address(0x123), hex"12345678");

        vm.prank(sequencerRole);
        sequencer.processTransaction(txn);

        assertEq(sequencer.getMempoolLength(), 0);
        assertEq(mockChain.getProcessedCount(), 1);
    }

    function testProcessTransactionWithRandomnessRequired() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(hex"12345678");

        // Add function selector to require randomness
        vm.prank(functionSelectorAdmin);
        sequencer.addToFunctionAllowlist(targetContract, selector);

        bytes memory txn = _createType2MockTransaction(targetContract, abi.encodePacked(selector));

        vm.prank(sequencerRole);
        vm.expectEmit(false, false, false, true);
        emit MempoolUpdated(1, txn);
        sequencer.processTransaction(txn);

        assertEq(sequencer.getMempoolLength(), 1);
        assertEq(mockChain.getProcessedCount(), 0);
    }

    function testProcessTransactionUnauthorized() public {
        bytes memory txn = _createType2MockTransaction(address(0x123), hex"12345678");

        vm.prank(unauthorized);
        vm.expectRevert();
        sequencer.processTransaction(txn);
    }

    function testProcessTransactionsBulk() public {
        bytes[] memory txns = new bytes[](2);
        txns[0] = _createType2MockTransaction(address(0x123), hex"12345678");
        txns[1] = _createType2MockTransaction(address(0x456), hex"87654321");

        vm.prank(sequencerRole);
        sequencer.processTransactionsBulk(txns);

        assertEq(sequencer.getMempoolLength(), 0);
        assertEq(mockChain.getProcessedCount(), 2);
    }

    function testProcessTransactionsBulkUnauthorized() public {
        bytes[] memory txns = new bytes[](1);
        txns[0] = _createType2MockTransaction(address(0x123), hex"12345678");

        vm.prank(unauthorized);
        vm.expectRevert();
        sequencer.processTransactionsBulk(txns);
    }

    function testProcessRandomTransactionProcessesMempool() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(hex"12345678");

        // Add function selector to require randomness
        vm.prank(functionSelectorAdmin);
        sequencer.addToFunctionAllowlist(targetContract, selector);

        // Add transactions to mempool
        bytes memory txn1 = _createType2MockTransaction(targetContract, abi.encodePacked(selector));
        bytes memory txn2 = _createType2MockTransaction(targetContract, abi.encodePacked(selector));

        vm.prank(sequencerRole);
        sequencer.processTransaction(txn1);
        vm.prank(sequencerRole);
        sequencer.processTransaction(txn2);

        assertEq(sequencer.getMempoolLength(), 2);

        // Add randomness transaction
        bytes memory randomnessTx = _createType2MockTransaction(address(0x999), hex"abcdef");

        vm.prank(randomnessRole);
        vm.expectEmit(false, false, false, false);
        emit MempoolCleared();
        sequencer.processRandomTransaction(randomnessTx);

        // Mempool should be cleared
        assertEq(sequencer.getMempoolLength(), 0);

        // Mock chain should have processed randomness tx + bulk mempool
        assertEq(mockChain.getProcessedCount(), 1); // randomness tx
        assertEq(mockChain.getProcessedBulkCount(), 1); // mempool bulk
    }

    function testProcessRandomTransactionUnauthorized() public {
        bytes memory randomnessTx = _createType2MockTransaction(address(0x999), hex"abcdef");

        vm.prank(unauthorized);
        vm.expectRevert();
        sequencer.processRandomTransaction(randomnessTx);
    }

    function testProcessRandomTransactionWithEmptyMempool() public {
        bytes memory randomnessTx = _createType2MockTransaction(address(0x999), hex"abcdef");

        vm.prank(randomnessRole);
        sequencer.processRandomTransaction(randomnessTx);

        assertEq(mockChain.getProcessedCount(), 1);
        assertEq(mockChain.getProcessedBulkCount(), 0);
    }

    function testTransactionNoncesIncrement() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(hex"12345678");

        // Add function selector to require randomness
        vm.prank(functionSelectorAdmin);
        sequencer.addToFunctionAllowlist(targetContract, selector);

        // Process multiple transactions
        bytes memory txn1 = _createType2MockTransaction(targetContract, abi.encodePacked(selector));
        bytes memory txn2 = _createType2MockTransaction(targetContract, abi.encodePacked(selector));

        vm.prank(sequencerRole);
        sequencer.processTransaction(txn1);
        vm.prank(sequencerRole);
        sequencer.processTransaction(txn2);
    }

    function testMultipleFunctionSelectors() public {
        address contract1 = address(0x123);
        address contract2 = address(0x456);
        bytes4 selector1 = bytes4(hex"11111111");
        bytes4 selector2 = bytes4(hex"22222222");

        vm.startPrank(functionSelectorAdmin);
        sequencer.addToFunctionAllowlist(contract1, selector1);
        sequencer.addToFunctionAllowlist(contract2, selector2);
        vm.stopPrank();

        RandomnessSequencer.ContractFunction[] memory funcs = sequencer.getAllowlistedFunctions();
        assertEq(funcs.length, 2);
    }

    function testProcessLegacyTransactionWithoutRandomnessRequired() public {
        // Create a legacy transaction
        bytes memory txn = _createLegacyMockTransaction(address(0x123), hex"12345678");

        vm.prank(sequencerRole);
        sequencer.processTransaction(txn);

        assertEq(sequencer.getMempoolLength(), 0);
        assertEq(mockChain.getProcessedCount(), 1);
    }

    function testProcessLegacyTransactionWithRandomnessRequired() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(hex"12345678");

        // Add function selector to require randomness
        vm.prank(functionSelectorAdmin);
        sequencer.addToFunctionAllowlist(targetContract, selector);

        bytes memory txn = _createLegacyMockTransaction(targetContract, abi.encodePacked(selector));

        vm.prank(sequencerRole);
        vm.expectEmit(false, false, false, true);
        emit MempoolUpdated(1, txn);
        sequencer.processTransaction(txn);

        assertEq(sequencer.getMempoolLength(), 1);
        assertEq(mockChain.getProcessedCount(), 0);
    }

    function testProcessType1TransactionWithoutRandomnessRequired() public {
        // Create an EIP-2930 transaction
        bytes memory txn = _createType1MockTransaction(address(0x123), hex"12345678");

        vm.prank(sequencerRole);
        sequencer.processTransaction(txn);

        assertEq(sequencer.getMempoolLength(), 0);
        assertEq(mockChain.getProcessedCount(), 1);
    }

    function testProcessType1TransactionWithRandomnessRequired() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(hex"12345678");

        // Add function selector to require randomness
        vm.prank(functionSelectorAdmin);
        sequencer.addToFunctionAllowlist(targetContract, selector);

        bytes memory txn = _createType1MockTransaction(targetContract, abi.encodePacked(selector));

        vm.prank(sequencerRole);
        vm.expectEmit(false, false, false, true);
        emit MempoolUpdated(1, txn);
        sequencer.processTransaction(txn);

        assertEq(sequencer.getMempoolLength(), 1);
        assertEq(mockChain.getProcessedCount(), 0);
    }

    function testProcessMixedTransactionTypes() public {
        address targetContract = address(0x123);
        bytes4 selector = bytes4(hex"12345678");

        // Add function selector to require randomness
        vm.prank(functionSelectorAdmin);
        sequencer.addToFunctionAllowlist(targetContract, selector);

        // Add legacy, EIP-2930, and EIP-1559 transactions to mempool
        bytes memory legacyTxn = _createLegacyMockTransaction(targetContract, abi.encodePacked(selector));
        bytes memory eip2930Txn = _createType1MockTransaction(targetContract, abi.encodePacked(selector));
        bytes memory eip1559Txn = _createType2MockTransaction(targetContract, abi.encodePacked(selector));

        vm.prank(sequencerRole);
        sequencer.processTransaction(legacyTxn);
        vm.prank(sequencerRole);
        sequencer.processTransaction(eip2930Txn);
        vm.prank(sequencerRole);
        sequencer.processTransaction(eip1559Txn);

        assertEq(sequencer.getMempoolLength(), 3);

        // Process randomness transaction
        bytes memory randomnessTx = _createType2MockTransaction(address(0x999), hex"abcdef");

        vm.prank(randomnessRole);
        sequencer.processRandomTransaction(randomnessTx);

        // All transaction types should be processed
        assertEq(sequencer.getMempoolLength(), 0);
        assertEq(mockChain.getProcessedCount(), 1);
        assertEq(mockChain.getProcessedBulkCount(), 1);
    }

    // Helper function to create a real RLP-encoded EIP-2930 transaction (Type 1)
    function _createType1MockTransaction(address to, bytes memory data) internal pure returns (bytes memory) {
        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // Test private key

        // EIP-2930 transaction parameters
        uint256 chainId = 1;
        uint256 nonce = 0;
        uint256 gasPrice = 10 gwei;
        uint256 gasLimit = 100000;
        uint256 value = 0;
        bytes memory accessList = hex"c0"; // Empty access list

        // Build the unsigned transaction payload (8 items)
        bytes memory unsignedPayload = abi.encodePacked(
            _encodeUint(chainId),
            _encodeUint(nonce),
            _encodeUint(gasPrice),
            _encodeUint(gasLimit),
            _encodeAddress(to),
            _encodeUint(value),
            _encodeBytes(data),
            accessList
        );

        // Wrap in RLP list
        bytes memory rlpUnsigned = _encodeList(unsignedPayload);

        // Hash for signing: keccak256(0x01 || rlp(unsigned_tx))
        bytes32 txHash = keccak256(abi.encodePacked(bytes1(0x01), rlpUnsigned));

        // Sign the transaction
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, txHash);

        // Build the signed transaction (11 items: 8 unsigned + v, r, s)
        bytes memory signedPayload = abi.encodePacked(
            unsignedPayload,
            _encodeUint(v - 27), // EIP-2930 uses v - 27 (0 or 1)
            _encodeBytes32(r),
            _encodeBytes32(s)
        );

        // Wrap in RLP list and prepend 0x01
        return abi.encodePacked(bytes1(0x01), _encodeList(signedPayload));
    }

    // Helper function to create a real RLP-encoded legacy transaction (Type 0)
    function _createLegacyMockTransaction(address to, bytes memory data) internal pure returns (bytes memory) {
        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // Test private key

        // Legacy transaction parameters
        uint256 chainId = 1;
        uint256 nonce = 0;
        uint256 gasPrice = 10 gwei;
        uint256 gasLimit = 100000;
        uint256 value = 0;

        // Build the unsigned transaction payload for EIP-155
        // [nonce, gasPrice, gasLimit, to, value, data, chainId, 0, 0]
        bytes memory unsignedPayload = abi.encodePacked(
            _encodeUint(nonce),
            _encodeUint(gasPrice),
            _encodeUint(gasLimit),
            _encodeAddress(to),
            _encodeUint(value),
            _encodeBytes(data),
            _encodeUint(chainId),
            uint8(0x80), // RLP encoding of 0
            uint8(0x80) // RLP encoding of 0
        );

        // Wrap in RLP list
        bytes memory rlpUnsigned = _encodeList(unsignedPayload);

        // Hash for signing
        bytes32 txHash = keccak256(rlpUnsigned);

        // Sign the transaction
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, txHash);

        // Calculate EIP-155 v value: chainId * 2 + 35 + {0,1}
        uint256 vValue = chainId * 2 + 35 + (v - 27);

        // Build the signed transaction (9 items: 6 unsigned - chainId,0,0 + v, r, s)
        bytes memory signedPayload = abi.encodePacked(
            _encodeUint(nonce),
            _encodeUint(gasPrice),
            _encodeUint(gasLimit),
            _encodeAddress(to),
            _encodeUint(value),
            _encodeBytes(data),
            _encodeUint(vValue),
            _encodeBytes32(r),
            _encodeBytes32(s)
        );

        // Wrap in RLP list (no type prefix for legacy)
        return _encodeList(signedPayload);
    }

    // Helper function to create a real RLP-encoded EIP-1559 transaction (Type 2)
    function _createType2MockTransaction(address to, bytes memory data) internal pure returns (bytes memory) {
        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // Test private key

        // EIP-1559 transaction parameters
        uint256 chainId = 1;
        uint256 nonce = 0;
        uint256 maxPriorityFeePerGas = 1 gwei;
        uint256 maxFeePerGas = 10 gwei;
        uint256 gasLimit = 100000;
        uint256 value = 0;
        bytes memory accessList = hex"c0"; // Empty access list

        // Build the unsigned transaction payload (9 items)
        bytes memory unsignedPayload = abi.encodePacked(
            _encodeUint(chainId),
            _encodeUint(nonce),
            _encodeUint(maxPriorityFeePerGas),
            _encodeUint(maxFeePerGas),
            _encodeUint(gasLimit),
            _encodeAddress(to),
            _encodeUint(value),
            _encodeBytes(data),
            accessList
        );

        // Wrap in RLP list
        bytes memory rlpUnsigned = _encodeList(unsignedPayload);

        // Hash for signing: keccak256(0x02 || rlp(unsigned_tx))
        bytes32 txHash = keccak256(abi.encodePacked(bytes1(0x02), rlpUnsigned));

        // Sign the transaction
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, txHash);

        // Build the signed transaction (12 items: 9 unsigned + v, r, s)
        bytes memory signedPayload = abi.encodePacked(
            unsignedPayload,
            _encodeUint(v - 27), // EIP-1559 uses v - 27
            _encodeBytes32(r),
            _encodeBytes32(s)
        );

        // Wrap in RLP list and prepend 0x02
        return abi.encodePacked(bytes1(0x02), _encodeList(signedPayload));
    }

    // RLP encoding helpers
    function _encodeUint(uint256 value) internal pure returns (bytes memory) {
        if (value == 0) {
            return hex"80";
        }
        if (value < 128) {
            return abi.encodePacked(uint8(value));
        }
        bytes memory valueBytes = _toBytes(value);
        return abi.encodePacked(uint8(0x80 + valueBytes.length), valueBytes);
    }

    function _encodeBytes(bytes memory data) internal pure returns (bytes memory) {
        if (data.length == 0) {
            return hex"80";
        }
        if (data.length == 1 && uint8(data[0]) < 128) {
            return data;
        }
        if (data.length <= 55) {
            return abi.encodePacked(uint8(0x80 + data.length), data);
        }
        bytes memory lengthBytes = _toBytes(data.length);
        return abi.encodePacked(uint8(0xb7 + lengthBytes.length), lengthBytes, data);
    }

    function _encodeAddress(address addr) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x94), addr); // 0x94 = 0x80 + 20 bytes
    }

    function _encodeBytes32(bytes32 data) internal pure returns (bytes memory) {
        // Remove leading zeros
        uint256 i = 0;
        while (i < 32 && data[i] == 0) {
            i++;
        }
        if (i == 32) {
            return hex"80"; // All zeros
        }
        bytes memory trimmed = new bytes(32 - i);
        for (uint256 j = 0; j < 32 - i; j++) {
            trimmed[j] = data[i + j];
        }
        return _encodeBytes(trimmed);
    }

    function _encodeList(bytes memory data) internal pure returns (bytes memory) {
        if (data.length <= 55) {
            return abi.encodePacked(uint8(0xc0 + data.length), data);
        }
        bytes memory lengthBytes = _toBytes(data.length);
        return abi.encodePacked(uint8(0xf7 + lengthBytes.length), lengthBytes, data);
    }

    function _toBytes(uint256 value) internal pure returns (bytes memory) {
        if (value == 0) {
            return new bytes(0);
        }
        uint256 length = 0;
        uint256 temp = value;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        bytes memory result = new bytes(length);
        temp = value;
        for (uint256 i = length; i > 0; i--) {
            result[i - 1] = bytes1(uint8(temp & 0xff));
            temp >>= 8;
        }
        return result;
    }
}
