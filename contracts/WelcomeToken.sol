/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { Address, ERC721, ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// @title WelcomeToken - using as drop token to potential buyers.
contract WelcomeToken is ERC721Enumerable, Ownable {
    string public message;

    constructor(string memory _message)
        ERC721("DeFi Runners welcome ticket", "DFR-WT")
    {
        message = _message;
    }

    function drop(address[] memory _accounts) external onlyOwner {
        uint256 numberOfTokens = _accounts.length;
        uint256 lastTokenId = totalSupply();
        for (uint256 i; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), lastTokenId + i);
        }
    }

    function setMessage(string memory _message) external onlyOwner {
        message = _message;
    }
}
