/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Whitelist is Ownable {
    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;

    // keep track of those on whitelist who have claimed their NFT
    mapping(address => bool) public claimed;

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function getHash(address _account) external pure returns (bytes32 result) {
        result = keccak256(abi.encodePacked(_account));
    }

    function checkValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root, address _account) external pure returns (bool result) {
        result = MerkleProof.verify(
            merkleProof,
            root,
            keccak256(abi.encodePacked(_account))
        );
    }

    /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isNotClaimed() {
        require(!claimed[msg.sender], "NFT is already claimed by this wallet");
        _;
    }
}
