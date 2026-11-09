// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SentinelMint} from "../src/SentinelMint.sol";

/// @notice Deploy SentinelMint on Base Sepolia (84532).
///   forge script script/DeployMint.s.sol --rpc-url https://sepolia.base.org --broadcast
///   Env: DEPLOYER_PRIVATE_KEY (deployer EOA, also the AI agent for the demo).
contract DeployMint is Script {
    // Reactive callback proxy on Base Sepolia (dev.reactive.network).
    address internal constant CALLBACK_PROXY = 0x476F44b11F5C942c58f4c8E3d0300E5710743585;

    function run() external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address agent = vm.addr(pk);
        vm.startBroadcast(pk);
        SentinelMint mint = new SentinelMint(CALLBACK_PROXY, agent);
        vm.stopBroadcast();
        console.log("SentinelMint deployed at:", address(mint));
        console.log("agent (deployer):", agent);
    }
}
