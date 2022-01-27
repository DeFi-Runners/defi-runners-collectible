// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <1.0.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;

    mapping(address => uint256) private pendingWithdrawals;

    event Withdrawal(address indexed user, uint256 amount);
    event WithdrawPending(address indexed user, uint256 amount);

    /**
     * @notice Returns how much funds are available for manual withdraw due to failed transfers.
     */
    function getPendingWithdrawal(address user) public view returns (uint256) {
        return pendingWithdrawals[user];
    }

    /**
     * @notice Allows a user to manually withdraw funds which originally failed to transfer.
     */
    function withdraw() public nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds are pending withdrawal");
        pendingWithdrawals[msg.sender] = 0;
        (bool success, ) = msg.sender.call{ value: amount, gas: 21000 }("");
        require(success, "Ether withdraw failed");
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice Allows a user to manually withdraw funds which originally failed to transfer.
     */
    function withdrawTo(address _to) public nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds are pending withdrawal");
        pendingWithdrawals[msg.sender] = 0;
        (bool success, ) = _to.call{ value: amount, gas: 21000 }("");
        require(success, "Ether withdraw failed");
        emit Withdrawal(_to, amount);
    }

    function _sendValueWithFallbackWithdraw(
        address payable user,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = user.call{ value: amount, gas: 21000 }("");

        if (!success) {
            // Record failed sends for a withdrawal later
            // Transfers could fail if sent to a multisig with non-trivial receiver logic
            pendingWithdrawals[user] += amount;

            emit WithdrawPending(user, amount);
        }
    }
}
