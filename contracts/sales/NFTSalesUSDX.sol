/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IERC1155Collectible.sol";
import "../interfaces/IPartner.sol";

// @title NFTSalesUSDX - NFT sale by stablecoins one type
contract NFTSalesUSDX is ERC1155Holder, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Token {
        bool resolved;
        uint256 price;
    }

    struct Collectible {
        uint256 price; // in usd
    }

    IERC1155Collectible public immutable collection;
    address public immutable vesting;
    address public immutable refRegistry;

    bool public salesEnabled;

    uint256 public minBuy = 1e18;

    // @dev collections - list of resolved for sell stablecoins
    mapping(address => Token) public tokenInfo;
    // token id -> data
    mapping(uint256 => Collectible) public collectibleInfo;

    event Bought(address token, address from, uint256 tokenId, uint256 amount);
    event Deposited(address token, address from, uint256 amount);

    // `_collectionToken` - erc1155 token
    constructor(IERC1155Collectible _collectionToken, address _vesting, address _refRegistry) {
        require(
            address(_collectionToken) != address(0) &&
            address(_vesting) != address(0) &&
            address(_refRegistry) != address(0),
            "Token sell: wrong constructor arguments"
        );

        collection = _collectionToken;
        vesting = _vesting;
        refRegistry = _refRegistry;

        Token storage usdt = tokenInfo[0x55d398326f99059fF775485246999027B3197955];
        usdt.resolved = true;
        usdt.price = 1e18;

        Token storage busd = tokenInfo[0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56];
        busd.resolved = true;
        busd.price = 1e18;

        Token storage usdc = tokenInfo[0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d];
        usdc.resolved = true;
        usdc.price = 1e18;

        Token storage dai = tokenInfo[0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3];
        dai.resolved = true;
        dai.price = 1e18;

        collectibleInfo[1].price = 1e18;
        collectibleInfo[2].price = 769e14;
        collectibleInfo[3].price = 336e13;
        collectibleInfo[4].price = 541e12;
        collectibleInfo[5].price = 2086e10;
    }

    function buy(
        address _token,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _items,
        address _to,
        address _sponsor
    )
        external
        payable
        isSellApproved
    {
        require(_token != address(0), "Token sell: zero token");
        require(_to != address(0), "Token sell: buy for vitalik?");
        require(
            _items > 0,
            "Token sell: zero items, really?"
        );
        require(
            tokenInfo[_token].resolved,
            "Token sell: token is not accepted"
        );

        if (!IPartner(refRegistry).isUser(msg.sender)) {
            IPartner(refRegistry).register(msg.sender, _sponsor);
        }

        _buy(_token, _amount, _tokenId, _items, _to);
    }

    function sellSwitcher(bool _status) external onlyOwner {
        salesEnabled = _status;
    }

    function countBuyAmount(address _buyToken, uint _tokenId, uint _amount)
        external
        view
        returns (uint price)
    {
        require(
            _amount > 0,
            "Token sell: zero items, really?"
        );
        require(
            tokenInfo[_buyToken].resolved,
            "Token sell: token is not accepted"
        );

        price = _amount.mul(collectibleInfo[_tokenId].price.mul(tokenInfo[_buyToken].price).div(1e18));
    }

    function setMinBuy(uint256 _minBuy) external onlyOwner {
        minBuy = _minBuy;
    }

    function _buy(
        address _token,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _items,
        address _to
    ) internal {
        require(msg.value == 0, "Ether value not zero");

        uint256 price = _items.mul(collectibleInfo[_tokenId].price.mul(tokenInfo[_token].price).div(1e18));

        require(_amount >= minBuy, "Token sell: min buy, not enough to buy");
        require(_amount >= price, "Token sell: not enough to buy, low amount");

        IERC20(_token).safeTransferFrom(_msgSender(), vesting, _amount);
        collection.mint(_to, _tokenId, _items, "");
        emit Deposited(_token, msg.sender, _amount);
        emit Bought(_token, _to, _tokenId, _items);
    }

    modifier isSellApproved() {
        require(salesEnabled, "Sales disabled");
        _;
    }
}
