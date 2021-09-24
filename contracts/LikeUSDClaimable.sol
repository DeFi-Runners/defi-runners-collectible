pragma solidity ^0.8.4;

import "./interfaces/IERC1155Collectible.sol";

contract LikeUSDClaimable {

    uint256 public constant reward = 10;
    uint256 public constant rewardLimit = 100_000;

    uint256 public rewardsPaid;

    address public immutable token;
    uint256 public immutable tokenId;

    mapping (address => bool) public claimers;

    event Claimed(address indexed account);

    constructor(address _token, uint256 _tokenId) {
        token = _token;
        tokenId = _tokenId;
    }

    function claim() external {
        require(!claimers[msg.sender], "Reward already accepted");
        require(rewardsPaid <= rewardLimit, "All tokens claimed");

        claimers[msg.sender] = true;
        IERC1155Collectible(token).mint(msg.sender, tokenId, reward, "");
        emit Claimed(msg.sender);
    }
}