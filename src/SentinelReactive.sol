// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IReactive} from "reactive-lib/interfaces/IReactive.sol";
import {ISystemContract} from "reactive-lib/interfaces/ISystemContract.sol";

/// @title SentinelReactive — the Reactive Network leg of MintSentinel (v2, Omni-native)
/// @notice Lives on Reactive Lasna (5318007). Subscribes to SentinelMint's
///   MintRequested events on Base Sepolia (84532). On each event it drops
///   replays and emits a Callback that arms the gate back on Base Sepolia.
///   No off-chain bot keeps this alive: the chain itself reacts.
///
/// @dev v2 REWRITE — why v1 died (proven on-chain 9 Nov 2026, trigger tx
///   0xcf5939...1b23c7cb, Lasna block 7924555):
///   v1 inherited AbstractReactive (reactive-lib v0.2.0) whose react() is
///   guarded by `vmOnly`. detectVm() sets vm = (extcodesize(0xfffFfF) == 0).
///   On Omni Lasna the SystemContract at 0xfffFfF HAS code, so the single
///   deployed copy has vm=false and react() reverts with Error("VM only")
///   on EVERY trigger. That revert caused PaymentFailure (debt 0.0123389
///   REACT), BlacklistContract, and the subscription going INACTIVE — mint #1
///   never even got a trigger. The old RVM copy where vm=true no longer
///   exists post-Omni, and upstream reactive-lib master still ships the
///   same vmOnly code (diff empty 9 Nov 2026), so the lib pattern is broken
///   for NEW Omni contracts. v2 therefore does NOT inherit AbstractReactive:
///   it subscribes directly through the service and guards react() with the
///   address the network actually calls from — the Lasna system contract
///   0x8888888888888888888888888888888888888888 (proven direct caller in
///   the trigger receipt: it emitted ReactiveContractReverted after calling
///   our react()). The deployer/owner is also allowed, for manual testing.
///   Callback emission keeps the old format (supported indefinitely per the
///   Reactive roadmap).
///
/// @dev v2 also fixes a v1 logic bug: lastNonce started at 0 and the check
///   `nonce <= lastNonce` would have DROPPED mint #0 (nonce 0) even if
///   react() had not reverted. Replay protection is now a mapping, and
///   lastNonce only tracks the highest routed nonce for monitoring.
contract SentinelReactive is IReactive {
    /// @notice topic_0 of SentinelMint.MintRequested(address,uint256,uint256).
    uint256 internal constant MINT_TOPIC0 =
        uint256(keccak256("MintRequested(address,uint256,uint256)"));

    /// @notice REACTIVE_IGNORE wildcard, same value as reactive-lib's.
    uint256 internal constant REACTIVE_IGNORE =
        0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

    /// @notice Subscription service (has code on Omni Lasna; subscribe works).
    ISystemContract internal constant SERVICE =
        ISystemContract(payable(0x0000000000000000000000000000000000fffFfF));

    /// @notice Lasna system contract — the proven direct caller of react().
    address internal constant SYSTEM_CONTRACT =
        0x8888888888888888888888888888888888888888;

    uint256 public immutable originChainId;
    address public immutable origin;
    uint256 public immutable destinationChainId;
    address public immutable destination;
    uint64 public immutable callbackGasLimit;
    address public immutable owner;

    /// @notice Highest mint nonce already routed (monitoring only).
    uint256 public lastNonce;

    /// @notice Nonces already routed (replay protection, order-independent).
    mapping(uint256 => bool) public routed;

    event MintRouted(address indexed minter, uint256 indexed tokenId, uint256 nonce);
    event MintDropped(uint256 nonce, uint256 lastApplied);

    constructor(
        uint256 _originChainId,
        address _origin,
        uint256 _destinationChainId,
        address _destination,
        uint64 _callbackGasLimit
    ) {
        originChainId = _originChainId;
        origin = _origin;
        destinationChainId = _destinationChainId;
        destination = _destination;
        callbackGasLimit = _callbackGasLimit;
        owner = msg.sender;

        // Single Omni deployment: subscribe unconditionally. (v1's `if (!vm)`
        // evaluated the same way on Lasna, but the vm concept is dead here.)
        SERVICE.subscribe(
            _originChainId, _origin, MINT_TOPIC0, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
        );
    }

    /// @notice Accept lREACT funding for callback payments.
    receive() external payable {}

    /// @notice Called by the system contract when payment for a trigger /
    ///   callback is due. (IPayer requirement — v1 got this from
    ///   AbstractPayer; v2 implements it directly. Only the Lasna system
    ///   contract or the subscription service may collect.)
    function pay(uint256 amount) external override {
        require(
            msg.sender == SYSTEM_CONTRACT || msg.sender == address(SERVICE),
            "payer only"
        );
        require(address(this).balance >= amount, "Insufficient funds");
        if (amount > 0) {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "Transfer failed");
        }
    }

    /// @notice Network entry point: route a matched mint request to the gate.
    /// @dev Only the Lasna system contract (or the owner, for manual tests)
    ///   may call this — NOT vmOnly, which can never pass on Omni.
    function react(LogRecord calldata log) external override {
        require(
            msg.sender == SYSTEM_CONTRACT || msg.sender == owner,
            "system or owner only"
        );
        if (log.topic_0 == MINT_TOPIC0 && log._contract == origin && log.chain_id == originChainId) {
            _routeMint(log);
        }
    }

    function _routeMint(LogRecord calldata log) internal {
        address minter = address(uint160(log.topic_1));
        uint256 tokenId = log.topic_2;
        uint256 nonce = abi.decode(log.data, (uint256));

        if (routed[nonce]) {
            emit MintDropped(nonce, lastNonce);
            return;
        }
        routed[nonce] = true;
        if (nonce > lastNonce) {
            lastNonce = nonce;
        }

        // Leading zero address is the RVM-id placeholder the relayer fills in.
        bytes memory payload = abi.encodeWithSignature(
            "armMint(address,address,uint256,uint256)", address(0), minter, tokenId, nonce
        );
        emit Callback(destinationChainId, destination, callbackGasLimit, payload);
        emit MintRouted(minter, tokenId, nonce);
    }
}
