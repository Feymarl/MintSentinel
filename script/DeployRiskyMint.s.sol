// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SentinelMintRisky} from "../src/SentinelMintRisky.sol";

/// @notice Deploy SentinelMintRisky on Base Sepolia (84532).
///   forge script script/DeployRiskyMint.s.sol --rpc-url https://base-sepolia-rpc.publicnode.com --broadcast
///   Env: DEPLOYER_PRIVATE_KEY.
contract DeployRiskyMint is Script {
    address internal constant CALLBACK_PROXY = 0x476F44b11F5C942c58f4c8E3d0300E5710743585;

    function run() external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);
        SentinelMintRisky risky = new SentinelMintRisky(CALLBACK_PROXY, vm.addr(pk));
        vm.stopBroadcast();
        console.log("SentinelMintRisky deployed at:", address(risky));
    }
}
