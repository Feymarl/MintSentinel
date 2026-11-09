// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title MinimalERC721 — small self-contained ERC721 core for the demo
/// @notice Deliberately dependency-free (no OpenZeppelin fetch needed on this
///   box): implements the ERC721 surface the demo needs — mint, ownerOf,
///   balanceOf, transferFrom, approve, setApprovalForAll, tokenURI.
/// @dev Not audited, testnet demo only. tokenURI returns a plain data URI
///   with the token id; the gate logic lives in SentinelMint, not here.
abstract contract MinimalERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;
    string public symbol;

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    error NonexistentToken(uint256 tokenId);
    error IncorrectOwner(address sender, uint256 tokenId, address owner);
    error InvalidReceiver(address receiver);
    error InvalidApprover(address approver);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert NonexistentToken(tokenId);
        return owner;
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        if (_owners[tokenId] == address(0)) revert NonexistentToken(tokenId);
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert InvalidApprover(msg.sender);
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (to == address(0)) revert InvalidReceiver(to);
        if (from != owner) revert IncorrectOwner(msg.sender, tokenId, owner);
        if (
            msg.sender != owner && msg.sender != _tokenApprovals[tokenId]
                && !isApprovedForAll(owner, msg.sender)
        ) revert InvalidApprover(msg.sender);
        _transfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (_owners[tokenId] == address(0)) revert NonexistentToken(tokenId);
        return string(
            abi.encodePacked(
                "data:application/json,{\"name\":\"SentinelMint #",
                _toString(tokenId),
                "\",\"description\":\"MintSentinel demo mint - vetted by the MintGuard AI agent before claiming.\"}"
            )
        );
    }

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert InvalidReceiver(to);
        if (_owners[tokenId] != address(0)) revert IncorrectOwner(address(0), tokenId, _owners[tokenId]);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        delete _tokenApprovals[tokenId];
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
