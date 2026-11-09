// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IReactive} from "reactive-lib/interfaces/IReactive.sol";
import {ISystemContract} from "reactive-lib/interfaces/ISystemContract.sol";

/// @title SentinelReactiveV4 — the Reactive Network leg of MintSentinel (v4, Omni-native)
/// @notice Lives on Reactive Lasna (5318007). Subscribes to SentinelMint's
///   MintRequested events on Base Sepolia (84532). On each event it drops
///   replays and requests a callback that arms the gate back on Base Sepolia.
///   No off-chain bot keeps this alive: the chain itself reacts.
///
/// @dev v4 = v3 + coverDebt(). Why (proven on-chain 9 Nov 2026, Reactscan):
///   RISKY v3 (0xb899...) went INACTIVE with 0.017122 lREACT debt: its
///   nonce-2 callback ran while the contract was nearly unfunded (the
///   0.0195 funding landed AFTER react), so the callback went out on
///   credit -> debt -> subscription deactivated, and its nonce-3 event
///   never triggered. v3 had no way to pay the debt (pay() is system-only,
///   funding the contract does NOT auto-cover debt). v4 adds coverDebt()
///   (AbstractPayer pattern): anyone may call it; it reads
///   vendor.debt(address(this)) and pays it from this contract's balance,
///   resuming the subscription. OPERATIONAL RULE: fund 0.05 lREACT BEFORE
///   the first mint so the ~0.0171 callback fee is covered at request time.
///
/// @dev v3 FIX (kept): callbacks via SYSTEM.requestCallbackV_1_0 on
///   0x8888888888888888888888888888888888888888 — the legacy Callback event
///   FAILED on Omni Lasna ("Invalid format of Config field N"). Payload's
///   first argument stays address(0): the network replaces the first 160
///   bits with THIS contract's address. No vmOnly (reverts on Omni).
interface ISystemContractOmni {
    struct CallbackConfiguration_V_1_0 {
        uint256 chainId;
        address recipient;
        uint64 gasLimit;
        bytes payload;
    }

    function requestCallbackV_1_0(CallbackConfiguration_V_1_0 memory config_) external;
}

/// @notice Minimal vendor interface: only the debt getter we need.
interface IPayable {
    function debt(address _contract) external view returns (uint256);
}

contract SentinelReactiveV4 is IReactive {
    /// @notice topic_0 of SentinelMint.MintRequested(address,uint256,uint256).
    uint256 internal constant MINT_TOPIC0 =
        uint256(keccak256("MintRequested(address,uint256,uint256)"));

    /// @notice REACTIVE_IGNORE wildcard, same value as reactive-lib's.
    uint256 internal constant REACTIVE_IGNORE =
        0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

    /// @notice Subscription service (has code on Omni Lasna; subscribe works).
    ISystemContract internal constant SERVICE =
        ISystemContract(payable(0x0000000000000000000000000000000000fffFfF));

    /// @notice Lasna system contract — the proven direct caller of react(),
    ///   and the contract that accepts callback requests on Omni.
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

        SERVICE.subscribe(
            _originChainId, _origin, MINT_TOPIC0, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
        );
    }

    /// @notice Accept lREACT funding for callback payments.
    receive() external payable {}

    /// @notice Called by the system contract when payment for a trigger /
    ///   callback is due. Only the Lasna system contract or the subscription
    ///   service may collect.
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

    /// @notice Pay this contract's outstanding debt to the system contract,
    ///   resuming a deactivated subscription. Anyone may call it — the funds
    ///   can only go to the vendor, from this contract's own balance.
    function coverDebt() external {
        uint256 amount = IPayable(SYSTEM_CONTRACT).debt(address(this));
        require(address(this).balance >= amount, "Insufficient funds");
        if (amount > 0) {
            (bool success, ) = payable(SYSTEM_CONTRACT).call{value: amount}("");
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

        // First argument is the placeholder the network replaces with THIS
        // contract's address before the payload reaches the destination.
        bytes memory payload = abi.encodeWithSignature(
            "armMint(address,address,uint256,uint256)", address(0), minter, tokenId, nonce
        );
        // v3/v4: request the callback through the system contract (Omni way).
        // The legacy Callback event is deprecated and FAILED on Lasna.
        ISystemContractOmni(SYSTEM_CONTRACT).requestCallbackV_1_0(
            ISystemContractOmni.CallbackConfiguration_V_1_0({
                chainId: destinationChainId,
                recipient: destination,
                gasLimit: callbackGasLimit,
                payload: payload
            })
        );
        emit MintRouted(minter, tokenId, nonce);
    }
}
