/// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PartnersManageable is Ownable {
    mapping(address => bool) public managers;

    event ManagerSet(address, bool);

    function setManager(address _account, bool _status) external onlyOwner {
        managers[_account] = _status;
        emit ManagerSet(_account, _status);
    }

    modifier onlyManager() {
        require(managers[msg.sender], "Only partner manager");
        _;
    }
}
