/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface IERC1155Collectible {
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;
}