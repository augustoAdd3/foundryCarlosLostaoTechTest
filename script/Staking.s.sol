// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ProxyStaking} from "../src/Proxy.sol";
import {Staking} from "../src/Staking.sol";
import {Token} from "../src/Token.sol";
import "forge-std/Script.sol";

contract DeployingContract is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Token token = new Token("TEST", "TST");
        Staking staking = new Staking();
        ProxyStaking p = new ProxyStaking(address(staking), bytes(""));

        vm.stopBroadcast();
    }
}
