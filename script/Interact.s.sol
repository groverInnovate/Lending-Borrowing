// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingProtocol.sol";
import "../src/ERC20Mock.sol";

contract Interact is Script {
    LendingProtocol public lending;
    ERC20Mock public token;

    address user = vm.addr(0x1); // Test user address

    function run() external {
        vm.startBroadcast();

        lending = LendingProtocol(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        token = ERC20Mock(0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519);

        // Mint tokens for testing
        token.mint(user, 1000 ether);

        console.log("User balance:", token.balanceOf(user));

        // Approve the protocol to spend tokens
        vm.prank(user);
        token.approve(address(lending), 500 ether);

        // Supply tokens
        vm.prank(user);
        lending.supply(address(token), 500 ether);
        console.log(
            "User collateral after supply:",
            lending.users(user).collateral
        );

        // Borrow tokens
        vm.prank(user);
        lending.borrow(address(token), 200 ether);
        console.log("User debt after borrow:", lending.users(user).debt);

        vm.stopBroadcast();
    }
}
