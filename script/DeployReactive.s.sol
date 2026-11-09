// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SentinelReactive} from "../src/SentinelReactive.sol";

/// @notice Deploy SentinelReactive on Reactive Lasna (5318007).
///   forge script script/DeployReactive.s.sol --rpc-url https://lasna-rpc.rnk.dev/ --broadcast
///   Env: DEPLOYER_PRIVATE_KEY, MINT_ADDRESS (SentinelMint on Base Sepolia).
contract DeployReactive is Script {
    uint256 internal constant BASE_SEPOLIA = 84532;

    function run() external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address mint = vm.envAddress("MINT_ADDRESS");
        vm.startBroadcast(pk);
        // 200k gas is the documented callback budget for simple gate calls.
        SentinelReactive reactive = new SentinelReactive(
            BASE_SEPOLIA, mint, BASE_SEPOLIA, mint, 200_000
        );
        vm.stopBroadcast();
        console.log("SentinelReactive deployed at:", address(reactive));
        console.log("origin/destination (SentinelMint):", mint);
    }
}
