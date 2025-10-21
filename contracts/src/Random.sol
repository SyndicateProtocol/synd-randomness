// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IRandom} from "./interfaces/IRandom.sol";

contract Random is AccessControl, IRandom {
    bytes32 public constant RANDOM_ADMIN_ROLE = keccak256("RANDOM_ADMIN_ROLE");
    uint256 public random;

    modifier onlyRandomAdmin() {
        _onlyRandomAdmin();
        _;
    }

    function _onlyRandomAdmin() internal view {
        require(hasRole(RANDOM_ADMIN_ROLE, msg.sender), "Caller is not the randomness admin");
    }

    constructor(address randomAdmin, address admin) {
        _grantRole(RANDOM_ADMIN_ROLE, randomAdmin);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function setRandom(uint256 _random) external onlyRandomAdmin {
        random = _random;
    }
}
