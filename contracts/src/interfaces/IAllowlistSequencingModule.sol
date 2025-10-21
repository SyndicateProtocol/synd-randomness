// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {IPermissionModule} from "./IPermissionModule.sol";

/**
 * @title IAllowlistSequencingModule
 * @dev Interface for the AllowlistSequencingModule contract.
 */
interface IAllowlistSequencingModule is IPermissionModule {
    /// @notice Emitted when a user is added to the allowlist.
    event UserAdded(address indexed user);

    /// @notice Emitted when a user is removed from the allowlist.
    event UserRemoved(address indexed user);

    /// @notice Emitted when the admin role is transferred.
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /// @notice Thrown when the caller is not the admin.
    error NotAdmin();

    /// @notice Thrown when an invalid address is provided.
    error AddressNotAllowed();

    /**
     * @notice Returns the current admin address.
     * @return The address of the admin.
     */
    function admin() external view returns (address);

    /**
     * @notice Checks if an address is on the allowlist.
     * @param user The address to check.
     * @return True if the address is allowed, false otherwise.
     */
    function allowlist(address user) external view returns (bool);

    /**
     * @notice Adds an address to the allowlist.
     * @param user The address to be added to the allowlist.
     */
    function addToAllowlist(address user) external;

    /**
     * @notice Removes an address from the allowlist.
     * @param user The address to be removed from the allowlist.
     */
    function removeFromAllowlist(address user) external;

    /**
     * @notice Transfers the admin role to a new address.
     * @param newAdmin The address of the new admin. Cannot be address(0).
     */
    function transferAdmin(address newAdmin) external;
}
