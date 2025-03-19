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

       
        token = new ERC20Mock("Test Token", "TST", 1_000_000 ether);

        
        lending = new LendingProtocol(msg.sender);

        
        lending.setBorrowRate(address(token), 10);   
        lending.setSupplyRate(address(token), 5);   

        console.log("Deployed LendingProtocol at:", address(lending));
        console.log("Deployed TestToken at:", address(token));

        vm.stopBroadcast();
    }
}

