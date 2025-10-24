// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {RLPReader} from "./RLPReader.sol";

/**
 * @title RLPTxBreakdown
 * @notice A library for decoding raw Ethereum transactions and breaking them down into their components.
 * @dev Supports both legacy transactions and EIP-1559 transactions (type 0x02).
 */
library RLPTxBreakdown {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    enum TxType {
        Legacy,
        EIP2930,
        EIP1559
    }

    struct DecodedTransaction {
        TxType txType;
        uint256 chainId;
        uint256 nonce;
        uint256 maxPriorityFeePerGas; // For legacy: same as gasPrice
        uint256 maxFeePerGas; // For legacy: same as gasPrice
        uint256 gasLimit;
        uint256 value;
        bytes data;
        address to; // address(0) for contract deployments
        address from;
    }

    /**
     * @notice Decode an Ethereum transaction.
     * @param txData The raw transaction data.
     * @return decodedTx The decoded transaction.
     */
    function decodeTx(bytes calldata txData) external pure returns (DecodedTransaction memory) {
        require(txData.length > 0, "Empty tx");

        // Check transaction type based on first byte
        if (txData[0] == 0x01) {
            return _decodeEIP2930Tx(txData);
        } else if (txData[0] == 0x02) {
            return _decodeEIP1559Tx(txData);
        } else {
            return _decodeLegacyTx(txData);
        }
    }

    /**
     * @notice Decode an EIP-2930 transaction.
     * @param txData The raw transaction data.
     * @return decodedTx The decoded transaction.
     */
    function _decodeEIP2930Tx(bytes calldata txData) internal pure returns (DecodedTransaction memory) {
        // Remove the type byte.
        bytes memory rlpTx = _slice(txData, 1, txData.length - 1);
        RLPReader.RLPItem memory txItem = rlpTx.toRlpItem();
        RLPReader.RLPItem[] memory items = txItem.toList();
        require(items.length == 11, "Invalid EIP-2930 tx");

        // If 'to' field is empty, it's a contract deployment (address(0))
        address toAddress = items[4].toBytes().length == 0 ? address(0) : items[4].toAddress();

        // Build unsigned payload from first 8 RLP items.
        bytes memory unsignedPayload = abi.encodePacked(
            // chainId - Chain ID of the network
            items[0].toRlpBytes(),
            // nonce - Transaction nonce of the sender account
            items[1].toRlpBytes(),
            // gasPrice - Gas price the sender is willing to pay
            items[2].toRlpBytes(),
            // gasLimit - Gas limit for the transaction
            items[3].toRlpBytes(),
            // to - Recipient address (20-byte Ethereum address)
            items[4].toRlpBytes(),
            // value - Amount of ETH (in wei) to transfer
            items[5].toRlpBytes(),
            // data - Transaction payload
            items[6].toRlpBytes(),
            // accessList - EIP-2930 access list
            items[7].toRlpBytes()
        );

        uint256 gasPrice = items[2].toUint();

        return DecodedTransaction({
            txType: TxType.EIP2930,
            chainId: items[0].toUint(),
            nonce: items[1].toUint(),
            maxPriorityFeePerGas: gasPrice, // EIP-2930 uses gasPrice
            maxFeePerGas: gasPrice,
            gasLimit: items[3].toUint(),
            value: items[5].toUint(),
            data: items[6].toBytes(),
            to: toAddress,
            from: _getAddressEIP2930(unsignedPayload, items)
        });
    }

    /**
     * @notice Decode an EIP-1559 transaction.
     * @param txData The raw transaction data.
     * @return decodedTx The decoded transaction.
     */
    function _decodeEIP1559Tx(bytes calldata txData) internal pure returns (DecodedTransaction memory) {
        // Remove the type byte.
        bytes memory rlpTx = _slice(txData, 1, txData.length - 1);
        RLPReader.RLPItem memory txItem = rlpTx.toRlpItem();
        RLPReader.RLPItem[] memory items = txItem.toList();
        require(items.length == 12, "Invalid EIP-1559 tx");

        // If 'to' field is empty, it's a contract deployment (address(0))
        address toAddress = items[5].toBytes().length == 0 ? address(0) : items[5].toAddress();

        // Build unsigned payload from first 9 RLP items.
        bytes memory unsignedPayload = abi.encodePacked(
            // chainId - Chain ID of the network (for example, 1 for Ethereum Mainnet).
            items[0].toRlpBytes(),
            // nonce - Transaction nonce of the sender account.
            items[1].toRlpBytes(),
            // maxPriorityFeePerGas - Tip cap (max priority fee per gas the sender is willing to pay).
            items[2].toRlpBytes(),
            // maxFeePerGas - Max total fee (inclusive of base fee and tip) the sender will pay.
            items[3].toRlpBytes(),
            // gasLimit - Gas limit for the transaction.
            items[4].toRlpBytes(),
            // to - Recipient address (20-byte Ethereum address). This is an empty byte string if the transaction is contract creation.
            items[5].toRlpBytes(),
            // value - Amount of ETH (in wei) to transfer.
            items[6].toRlpBytes(),
            // data - Transaction payload (the calldata for a contract call, or contract creation bytecode).
            items[7].toRlpBytes(),
            // accessList - EIP-2930 access list (list of address/storage key tuples); can be an empty list.
            items[8].toRlpBytes()
        );
        return DecodedTransaction({
            txType: TxType.EIP1559,
            chainId: items[0].toUint(),
            nonce: items[1].toUint(),
            maxPriorityFeePerGas: items[2].toUint(),
            maxFeePerGas: items[3].toUint(),
            gasLimit: items[4].toUint(),
            value: items[6].toUint(),
            data: items[7].toBytes(),
            to: toAddress,
            from: _getAddressEIP1559(unsignedPayload, items)
        });
    }

    /**
     * @notice Decode a legacy transaction.
     * @param txData The raw transaction data.
     * @return decodedTx The decoded transaction.
     */
    function _decodeLegacyTx(bytes calldata txData) internal pure returns (DecodedTransaction memory) {
        RLPReader.RLPItem memory txItem = txData.toRlpItem();
        RLPReader.RLPItem[] memory items = txItem.toList();
        require(items.length == 9, "Invalid legacy tx");

        // If 'to' field is empty, it's a contract deployment (address(0))
        address toAddress = items[3].toBytes().length == 0 ? address(0) : items[3].toAddress();

        // Build unsigned payload from first 6 RLP items + chainId for EIP-155
        uint256 v = items[6].toUint();
        uint256 chainId;

        // Extract chainId from v (EIP-155: v = chainId * 2 + 35 + {0,1})
        if (v >= 35) {
            chainId = (v - 35) / 2;
        } else {
            chainId = 0; // Pre-EIP-155 transaction
        }

        uint256 gasPrice = items[1].toUint();

        return DecodedTransaction({
            txType: TxType.Legacy,
            chainId: chainId,
            nonce: items[0].toUint(),
            maxPriorityFeePerGas: gasPrice, // Legacy uses gasPrice for both
            maxFeePerGas: gasPrice,
            gasLimit: items[2].toUint(),
            value: items[4].toUint(),
            data: items[5].toBytes(),
            to: toAddress,
            from: _getAddressLegacy(items, chainId)
        });
    }

    /**
     * @notice Given the unsigned payload, recovers the sender address for EIP-2930 transactions.
     * @param unsignedPayload The unsigned payload of the transaction.
     * @param items The RLP items of the transaction.
     * @return sender The sender address
     */
    function _getAddressEIP2930(bytes memory unsignedPayload, RLPReader.RLPItem[] memory items)
        internal
        pure
        returns (address sender)
    {
        // RLP-encode the unsigned payload.
        bytes memory encodedUnsigned;
        if (unsignedPayload.length < 56) {
            encodedUnsigned = abi.encodePacked(uint8(0xc0 + unsignedPayload.length), unsignedPayload);
        } else {
            uint256 len = unsignedPayload.length;
            uint256 lenLen;
            uint256 tmp = len;
            while (tmp != 0) {
                lenLen++;
                tmp >>= 8;
            }
            bytes memory lenBytes = new bytes(lenLen);
            tmp = len;
            for (uint256 i = 0; i < lenLen; i++) {
                lenBytes[lenLen - 1 - i] = bytes1(uint8(tmp & 0xFF));
                tmp >>= 8;
            }
            encodedUnsigned = abi.encodePacked(uint8(0xf7 + lenLen), lenBytes, unsignedPayload);
        }
        // Prepend type byte 0x01.
        bytes32 msgHash = keccak256(abi.encodePacked(bytes1(0x01), encodedUnsigned));

        // Extract and normalize v (EIP-2930 uses v values 0 or 1, need to add 27)
        uint8 v = uint8(uint256(items[8].toUint())) + 27;
        bytes32 r = _toBytes32(items[9]);
        bytes32 s = _toBytes32(items[10]);
        return ecrecover(msgHash, v, r, s);
    }

    /**
     * @notice Given the unsigned payload, recovers the sender address for EIP-1559 transactions.
     * @param unsignedPayload The unsigned payload of the transaction.
     * @param items The RLP items of the transaction.
     * @return sender The sender address
     */
    function _getAddressEIP1559(bytes memory unsignedPayload, RLPReader.RLPItem[] memory items)
        internal
        pure
        returns (address sender)
    {
        // RLP-encode the unsigned payload.
        bytes memory encodedUnsigned;
        if (unsignedPayload.length < 56) {
            encodedUnsigned = abi.encodePacked(uint8(0xc0 + unsignedPayload.length), unsignedPayload);
        } else {
            uint256 len = unsignedPayload.length;
            uint256 lenLen;
            uint256 tmp = len;
            while (tmp != 0) {
                lenLen++;
                tmp >>= 8;
            }
            bytes memory lenBytes = new bytes(lenLen);
            tmp = len;
            for (uint256 i = 0; i < lenLen; i++) {
                lenBytes[lenLen - 1 - i] = bytes1(uint8(tmp & 0xFF));
                tmp >>= 8;
            }
            encodedUnsigned = abi.encodePacked(uint8(0xf7 + lenLen), lenBytes, unsignedPayload);
        }
        // Prepend type byte 0x02.
        bytes32 msgHash = keccak256(abi.encodePacked(bytes1(0x02), encodedUnsigned));

        // Adjust v and recover the sender address.
        uint8 v = uint8(uint256(items[9].toUint())) + 27;
        bytes32 r = _toBytes32(items[10]);
        bytes32 s = _toBytes32(items[11]);
        return ecrecover(msgHash, v, r, s);
    }

    /**
     * @notice Recovers the sender address for legacy transactions.
     * @param items The RLP items of the transaction.
     * @param chainId The chain ID extracted from v.
     * @return sender The sender address
     */
    function _getAddressLegacy(RLPReader.RLPItem[] memory items, uint256 chainId)
        internal
        pure
        returns (address sender)
    {
        // Build unsigned payload for legacy transaction
        bytes memory unsignedPayload;

        if (chainId == 0) {
            // Pre-EIP-155: [nonce, gasPrice, gasLimit, to, value, data]
            unsignedPayload = abi.encodePacked(
                items[0].toRlpBytes(), // nonce
                items[1].toRlpBytes(), // gasPrice
                items[2].toRlpBytes(), // gasLimit
                items[3].toRlpBytes(), // to
                items[4].toRlpBytes(), // value
                items[5].toRlpBytes() // data
            );
        } else {
            // EIP-155: [nonce, gasPrice, gasLimit, to, value, data, chainId, 0, 0]
            unsignedPayload = abi.encodePacked(
                items[0].toRlpBytes(), // nonce
                items[1].toRlpBytes(), // gasPrice
                items[2].toRlpBytes(), // gasLimit
                items[3].toRlpBytes(), // to
                items[4].toRlpBytes(), // value
                items[5].toRlpBytes(), // data
                _encodeUint(chainId), // chainId
                uint8(0x80), // empty value (0)
                uint8(0x80) // empty value (0)
            );
        }

        // RLP-encode the unsigned payload
        bytes memory encodedUnsigned;
        if (unsignedPayload.length < 56) {
            encodedUnsigned = abi.encodePacked(uint8(0xc0 + unsignedPayload.length), unsignedPayload);
        } else {
            uint256 len = unsignedPayload.length;
            uint256 lenLen;
            uint256 tmp = len;
            while (tmp != 0) {
                lenLen++;
                tmp >>= 8;
            }
            bytes memory lenBytes = new bytes(lenLen);
            tmp = len;
            for (uint256 i = 0; i < lenLen; i++) {
                lenBytes[lenLen - 1 - i] = bytes1(uint8(tmp & 0xFF));
                tmp >>= 8;
            }
            encodedUnsigned = abi.encodePacked(uint8(0xf7 + lenLen), lenBytes, unsignedPayload);
        }

        bytes32 msgHash = keccak256(encodedUnsigned);

        // Extract signature values
        uint256 v = items[6].toUint();
        bytes32 r = _toBytes32(items[7]);
        bytes32 s = _toBytes32(items[8]);

        // Normalize v for ecrecover (should be 27 or 28)
        uint8 normalizedV;
        if (chainId == 0) {
            // Pre-EIP-155: v is already 27 or 28
            normalizedV = uint8(v);
        } else {
            // EIP-155: v = chainId * 2 + 35 + {0,1}, so extract the {0,1} and add 27
            normalizedV = uint8((v - 35 - chainId * 2) + 27);
        }

        return ecrecover(msgHash, normalizedV, r, s);
    }

    /**
     * @notice Internal helper function to slice a byte array.
     * @param data The byte array.
     * @param start The start index.
     * @param len The number of bytes to slice.
     * @return A new byte array containing the slice.
     */
    function _slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory) {
        bytes memory result = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = data[i + start];
        }
        return result;
    }

    /**
     * @notice Internal helper to convert an RLP item to a bytes32 value.
     * @param item The RLP item.
     * @return result The bytes32 representation.
     */
    function _toBytes32(RLPReader.RLPItem memory item) internal pure returns (bytes32 result) {
        bytes memory b = item.toBytes();
        require(b.length <= 32, "Invalid length");
        assembly {
            result := mload(add(b, 32))
        }
    }

    /**
     * @notice Internal helper to RLP-encode a uint256 value.
     * @param value The uint256 value to encode.
     * @return The RLP-encoded bytes.
     */
    function _encodeUint(uint256 value) internal pure returns (bytes memory) {
        if (value == 0) {
            return abi.encodePacked(uint8(0x80)); // RLP encoding of 0
        } else if (value < 0x80) {
            return abi.encodePacked(uint8(value)); // Single byte
        } else {
            // Multi-byte encoding
            uint256 len;
            uint256 tmp = value;
            while (tmp != 0) {
                len++;
                tmp >>= 8;
            }
            bytes memory valueBytes = new bytes(len);
            tmp = value;
            for (uint256 i = 0; i < len; i++) {
                valueBytes[len - 1 - i] = bytes1(uint8(tmp & 0xFF));
                tmp >>= 8;
            }
            return abi.encodePacked(uint8(0x80 + len), valueBytes);
        }
    }
}
