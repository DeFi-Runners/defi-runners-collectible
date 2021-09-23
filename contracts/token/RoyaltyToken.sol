/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IRoyaltiesProvider.sol";
import "./AbstractRoyalties.sol";

contract RoyaltyToken is IRoyaltiesProvider, AbstractRoyalties, Ownable {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getFeeRecipients(uint256 id) public override view returns (address payable[] memory) {
        LibPart.Part[] memory _royalties = royalties[id];
        address payable[] memory result = new address payable[](_royalties.length);
        for (uint i = 0; i < _royalties.length; i++) {
            result[i] = payable(_royalties[i].account);
        }
        return result;
    }

    function getFeeBps(uint256 id) public override view returns (uint[] memory) {
        LibPart.Part[] memory _royalties = royalties[id];
        uint[] memory result = new uint[](_royalties.length);
        for (uint i = 0; i < _royalties.length; i++) {
            result[i] = _royalties[i].value;
        }
        return result;
    }

    function getRoyalties(uint id) external virtual override returns (LibPart.Part[] memory) {
        return royalties[id];
    }

    function saveRoyalties(uint256 id, LibPart.Part[] memory royalties) external onlyOwner {
        _saveRoyalties(id, royalties);
    }

    function updateAccount(uint256 id, address from, address to) external onlyOwner {
        _updateAccount(id, from, to);
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }
}