// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IRandom} from "./interfaces/IRandom.sol";

contract DoSomethingWithRandom {
    IRandom public random;

    event GotRandom(uint256 random);

    constructor(address _random) {
        random = IRandom(_random);
    }

    function doSomethingWithRandom() external returns (uint256) {
        uint256 rand = random.random();
        emit GotRandom(rand);
        return rand;
    }
}
