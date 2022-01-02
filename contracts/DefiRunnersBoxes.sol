/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Address, ERC1155, ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title DefiRunnersBoxes
 */
contract DefiRunnersBoxes is ERC1155Supply, Ownable {

    string public name;
    string public symbol;

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
    )
        ERC1155(_uri)
    {
        name = _name;
        symbol = _symbol;
    }

    // @dev Mint NFTs.
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external onlyOwner {
        _mint(_to, _id, _amount, _data);
    }

    // @dev Mint batch NFTs.
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external onlyOwner {
        _mintBatch(_to, _ids, _amounts, _data);
    }

    // @dev Set metadata url.
    function setURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }
}
