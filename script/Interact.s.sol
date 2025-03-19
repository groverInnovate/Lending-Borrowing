// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingProtocol.sol";
import "../src/ERC20Mock.sol";

contract Interact is Script {
    LendingProtocol lending;
    ERC20Mock token;

    address user = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);  

    function run() external {
        vm.startBroadcast();

        lending = LendingProtocol(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        token = ERC20Mock(0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519);

       
        token.mint(user, 1000 ether);  

        
        token.approve(address(lending), 500 ether);
        lending.supply(address(token), 500 ether);

        lending.borrow(address(token), 200 ether);

        vm.stopBroadcast();
    }
}

