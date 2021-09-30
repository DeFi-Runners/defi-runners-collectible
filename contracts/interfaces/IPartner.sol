/// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IPartner {
    function register(address sender, address affiliate) external;
    function isUser(address _account) external view returns (bool);
}
