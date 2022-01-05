/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./RoyaltyToken.sol";

contract ERC1155Collectible is ERC1155Supply, RoyaltyToken {
    mapping(address => bool) public minters;
    mapping(uint256 => uint256) public tokensLimit;

    event MinterRoleGranted(address);
    event MinterRoleRevoked(address);

    constructor() ERC1155("") {
        tokensLimit[1] = 19_000_000;
        tokensLimit[2] = 120_000_000;
        tokensLimit[3] = 500_000_000;
        tokensLimit[4] = 1_000_000_000;
        tokensLimit[5] = 100_000_000_000;
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual {
        require(minters[msg.sender], "No permission Minter");

        _mint(_to, _id, _amount, _data);

        require(totalSupply(_id) <= tokensLimit[_id], "Limit overflow");
    }

    function burn(
        address _to,
        uint256 _id,
        uint256 _amount
    ) public virtual {
        require(minters[msg.sender], "No permission Minter");

        _burn(_to, _id, _amount);
    }

    function setMinter(address account, bool state) external onlyOwner {
        minters[account] = state;
        if (state) {
            emit MinterRoleGranted(account);
        } else {
            emit MinterRoleRevoked(account);
        }
    }

    function setUri(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }
}
