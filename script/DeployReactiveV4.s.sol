// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SentinelReactiveV4} from "../src/SentinelReactiveV4.sol";

/// @notice Deploy SentinelReactiveV4 on Reactive Lasna (5318007).
///   forge script script/DeployReactiveV4.s.sol --rpc-url https://lasna-rpc.rnk.dev/ --broadcast
///   Env: DEPLOYER_PRIVATE_KEY, MINT_ADDRESS (SentinelMintRisky on Base Sepolia).
/// @dev v4 = v3 + coverDebt() (see src/SentinelReactiveV4.sol). Deploy flags
///   that worked for v3 RISKY (21:44): --with-gas-price 100000000000
///   --gas-estimate-multiplier 110 --start-fresh. Fund 0.05 lREACT BEFORE
///   firing any mint — an unfunded first callback goes out on credit and
///   kills the subscription with debt (proven: RISKY v3, 0.017122 debt).
contract DeployReactiveV4 is Script {
    uint256 internal constant BASE_SEPOLIA = 84532;

    function run() external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address mint = vm.envAddress("MINT_ADDRESS");
        vm.startBroadcast(pk);
        SentinelReactiveV4 reactive = new SentinelReactiveV4(
            BASE_SEPOLIA, mint, BASE_SEPOLIA, mint, 500_000
        );
        vm.stopBroadcast();
        console.log("SentinelReactiveV4 deployed at:", address(reactive));
        console.log("origin/destination (SentinelMintRisky):", mint);
    }
}
