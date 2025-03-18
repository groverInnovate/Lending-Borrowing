// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingProtocol.sol";
import "../src/ERC20Mock.sol";

contract Deploy is Script {
    LendingProtocol public lending;
    ERC20Mock public token;

    function run() external {
        vm.startBroadcast();

        // Deploy the mock ERC20 token
        token = new ERC20Mock("Test Token", "TST", 1_000_000 ether);

        // Deploy the Lending Protocol contract
        lending = new LendingProtocol(msg.sender);

        // ✅ Use the setter functions
        lending.setBorrowRate(address(token), 10);   // 10% borrow rate
        lending.setSupplyRate(address(token), 5);    // 5% supply rate

        console.log("Deployed LendingProtocol at:", address(lending));
        console.log("Deployed TestToken at:", address(token));

        vm.stopBroadcast();
    }
}

