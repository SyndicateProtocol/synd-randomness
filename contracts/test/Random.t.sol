// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {Random} from "../src/Random.sol";

contract RandomTest is Test {
    Random public randomContract;

    address public defaultAdmin = address(1);
    address public randomAdmin = address(2);
    address public unauthorized = address(3);

    function setUp() public {
        randomContract = new Random(randomAdmin, defaultAdmin);
    }

    function testConstructor() public view {
        assertTrue(randomContract.hasRole(randomContract.DEFAULT_ADMIN_ROLE(), defaultAdmin));
        assertTrue(randomContract.hasRole(randomContract.RANDOM_ADMIN_ROLE(), randomAdmin));
    }

    function testSetRandom() public {
        uint256 newRandom = 123456789;

        vm.prank(randomAdmin);
        randomContract.setRandom(newRandom);

        assertEq(randomContract.random(), newRandom);
    }

    function testSetRandomUnauthorized() public {
        uint256 newRandom = 123456789;

        vm.prank(unauthorized);
        vm.expectRevert("Caller is not the randomness admin");
        randomContract.setRandom(newRandom);
    }

    function testSetRandomMultipleTimes() public {
        vm.startPrank(randomAdmin);

        randomContract.setRandom(111);
        assertEq(randomContract.random(), 111);

        randomContract.setRandom(222);
        assertEq(randomContract.random(), 222);

        randomContract.setRandom(333);
        assertEq(randomContract.random(), 333);

        vm.stopPrank();
    }

    function testFuzzSetRandom(uint256 randomValue) public {
        vm.prank(randomAdmin);
        randomContract.setRandom(randomValue);

        assertEq(randomContract.random(), randomValue);
    }

    function testRandomDefaultValue() public view {
        assertEq(randomContract.random(), 0);
    }

    function testGrantrandomAdminRole() public {
        address newAdmin = address(3);

        vm.startPrank(defaultAdmin);
        randomContract.grantRole(randomContract.RANDOM_ADMIN_ROLE(), newAdmin);
        vm.stopPrank();

        assertTrue(randomContract.hasRole(randomContract.RANDOM_ADMIN_ROLE(), newAdmin));

        // New admin should be able to set random
        vm.prank(newAdmin);
        randomContract.setRandom(999);
        assertEq(randomContract.random(), 999);
    }

    function testRevokerandomAdminRole() public {
        vm.startPrank(defaultAdmin);
        randomContract.revokeRole(randomContract.RANDOM_ADMIN_ROLE(), randomAdmin);
        vm.stopPrank();

        assertFalse(randomContract.hasRole(randomContract.RANDOM_ADMIN_ROLE(), randomAdmin));

        // Revoked admin should not be able to set random
        vm.prank(defaultAdmin);
        vm.expectRevert("Caller is not the randomness admin");
        randomContract.setRandom(123);
    }

    function testMultipleAdmins() public {
        address admin2 = address(3);
        address admin3 = address(4);

        vm.startPrank(defaultAdmin);
        randomContract.grantRole(randomContract.RANDOM_ADMIN_ROLE(), admin2);
        randomContract.grantRole(randomContract.RANDOM_ADMIN_ROLE(), admin3);
        vm.stopPrank();

        // All admins can set random
        vm.prank(randomAdmin);
        randomContract.setRandom(100);
        assertEq(randomContract.random(), 100);

        vm.prank(admin2);
        randomContract.setRandom(200);
        assertEq(randomContract.random(), 200);

        vm.prank(admin3);
        randomContract.setRandom(300);
        assertEq(randomContract.random(), 300);
    }
}
