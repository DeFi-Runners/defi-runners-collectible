// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
pragma abicoder v2;

import "../libs/LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(uint tokenId) external returns (LibPart.Part[] memory);
    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
    function getFeeBps(uint256 id) external view returns (uint[] memory);
}
