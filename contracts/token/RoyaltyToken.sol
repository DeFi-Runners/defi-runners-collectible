/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IRoyaltiesProvider.sol";
import "./AbstractRoyalties.sol";

contract RoyaltyToken is IRoyaltiesProvider, AbstractRoyalties, Ownable {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getFeeRecipients(uint256 id)
        public
        view
        override
        returns (address payable[] memory)
    {
        LibPart.Part[] memory _royalties = royalties[id];
        address payable[] memory result = new address payable[](
            _royalties.length
        );
        for (uint256 i = 0; i < _royalties.length; i++) {
            result[i] = payable(_royalties[i].account);
        }
        return result;
    }

    function getFeeBps(uint256 id)
        public
        view
        override
        returns (uint256[] memory)
    {
        LibPart.Part[] memory _royalties = royalties[id];
        uint256[] memory result = new uint256[](_royalties.length);
        for (uint256 i = 0; i < _royalties.length; i++) {
            result[i] = _royalties[i].value;
        }
        return result;
    }

    function getRoyalties(uint256 id)
        external
        virtual
        override
        returns (LibPart.Part[] memory)
    {
        return royalties[id];
    }

    function saveRoyalties(uint256 id, LibPart.Part[] memory royalties)
        external
        onlyOwner
    {
        _saveRoyalties(id, royalties);
    }

    function updateAccount(
        uint256 id,
        address from,
        address to
    ) external onlyOwner {
        _updateAccount(id, from, to);
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties)
        internal
        override
    {
        emit RoyaltiesSet(id, _royalties);
    }
}
