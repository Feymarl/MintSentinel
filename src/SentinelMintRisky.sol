// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MinimalERC721} from "./MinimalERC721.sol";
import {AbstractCallback} from "reactive-lib/abstract-base/AbstractCallback.sol";

/// @title SentinelMintRisky — the RISKY leg of the MintSentinel demo
/// @notice Same gate flow as SentinelMint, but the mint is PAID: 0.0001 ETH.
///   The MintGuard vetting engine scores it RISKY (paid mint −25, value-0
///   simulation reverts −30 → ~45, mirroring the Arbitrum risky demo), so
///   the AI agent posts a RISKY verdict and claimMint() reverts on-chain —
///   the gate demonstrably blocks a risky mint. The 0.0001 ETH is a demo
///   price (deployer-funded, testnet only); the point is the verdict, not
///   the money.
/// @dev Identical loop wiring to SentinelMint (own reactive contract
///   instance subscribes to THIS origin). The armMint MintArmed nonce wart
///   from SentinelMint is fixed here (emits the real nonce).
contract SentinelMintRisky is MinimalERC721, AbstractCallback {
    event MintRequested(address indexed minter, uint256 indexed tokenId, uint256 nonce);
    event MintArmed(address indexed minter, uint256 indexed tokenId, uint256 nonce);
    event VerdictSubmitted(uint256 indexed tokenId, bool safe, uint8 score, string reason);
    event MintClaimed(address indexed minter, uint256 indexed tokenId);

    enum Status {
        NONE,
        REQUESTED,
        PENDING,
        SAFE,
        RISKY,
        CLAIMED
    }

    struct Mint {
        address minter;
        Status status;
        uint8 score;
        string reason;
    }

    uint256 public nextTokenId;
    uint256 public nextNonce;
    mapping(uint256 => Mint) public mints;

    /// @notice The off-chain AI vetting agent allowed to submit verdicts.
    address public agent;

    /// @notice Demo mint price: 0.0001 ETH. Readable via mintPrice() so the
    ///   vetting engine sees it (paid_mint −25). Small on purpose: the
    ///   deployer only holds ~0.002 Base Sepolia ETH.
    uint256 public mintPrice = 0.0001 ether;

    error NotAgent();
    error BadStatus();

    /// @param callbackProxy Reactive callback proxy on Base Sepolia:
    ///   0x476F44b11F5C942c58f4c8E3d0300E5710743585
    constructor(address callbackProxy, address _agent)
        MinimalERC721("SentinelMintRisky", "SENT-RISKY")
        AbstractCallback(callbackProxy)
    {
        agent = _agent;
    }

    /// @notice Paid mint request. Emits the event the reactive contract watches.
    function requestMint() external payable returns (uint256 tokenId) {
        require(msg.value >= mintPrice, "pay mint price");
        tokenId = nextTokenId++;
        uint256 nonce = nextNonce++;
        mints[tokenId] = Mint(msg.sender, Status.REQUESTED, 0, "");
        emit MintRequested(msg.sender, tokenId, nonce);
    }

    /// @notice Called ONLY via the Reactive callback (authorizedSenderOnly).
    ///   Arms the gate: the mint is now waiting for the AI verdict.
    function armMint(address /* rvmId */, address minter, uint256 tokenId, uint256 nonce)
        external
        authorizedSenderOnly
    {
        Mint storage m = mints[tokenId];
        require(m.minter == minter && m.status == Status.REQUESTED, "bad mint");
        m.status = Status.PENDING;
        emit MintArmed(minter, tokenId, nonce);
    }

    /// @notice AI vetting agent posts its verdict (Sourcify + simulation score).
    function submitVerdict(uint256 tokenId, bool safe, uint8 score, string calldata reason) external {
        if (msg.sender != agent) revert NotAgent();
        Mint storage m = mints[tokenId];
        if (m.status != Status.PENDING) revert BadStatus();
        m.status = safe ? Status.SAFE : Status.RISKY;
        m.score = score;
        m.reason = reason;
        emit VerdictSubmitted(tokenId, safe, score, reason);
    }

    /// @notice Claim the NFT. Reverts unless the AI verdict was SAFE.
    function claimMint(uint256 tokenId) external {
        Mint storage m = mints[tokenId];
        if (m.minter != msg.sender || m.status != Status.SAFE) revert BadStatus();
        m.status = Status.CLAIMED;
        _mint(msg.sender, tokenId);
        emit MintClaimed(msg.sender, tokenId);
    }
}
