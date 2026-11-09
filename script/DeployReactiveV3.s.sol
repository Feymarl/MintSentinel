// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SentinelReactiveV3} from "../src/SentinelReactiveV3.sol";

/// @notice Deploy SentinelReactiveV3 on Reactive Lasna (5318007).
///   forge script script/DeployReactiveV3.s.sol --rpc-url https://lasna-rpc.rnk.dev/ --broadcast
///   Env: DEPLOYER_PRIVATE_KEY, MINT_ADDRESS (SentinelMint on Base Sepolia).
/// @dev v3 requests callbacks via SYSTEM.requestCallbackV_1_0 (Omni way);
///   the legacy Callback event FAILED on Lasna ("Invalid format of Config
///   field N"). Callback gas 500k: above the 100k minimum, near the 600k
///   of a verified working third-party callback, covers armMint + proxy
///   overhead.
contract DeployReactiveV3 is Script {
    uint256 internal constant BASE_SEPOLIA = 84532;

    function run() external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address mint = vm.envAddress("MINT_ADDRESS");
        vm.startBroadcast(pk);
        SentinelReactiveV3 reactive = new SentinelReactiveV3(
            BASE_SEPOLIA, mint, BASE_SEPOLIA, mint, 500_000
        );
        vm.stopBroadcast();
        console.log("SentinelReactiveV3 deployed at:", address(reactive));
        console.log("origin/destination (SentinelMint):", mint);
    }
}
