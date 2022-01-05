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
import "../oracles/IUniV2PriceOracle.sol";

// @title NFTSalesBNB - NFT sale in BNB
contract NFTSalesBNB is ERC1155Holder, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Token {
        bool resolved;
        uint256 price;
        IUniV2PriceOracle priceOracle;
    }

    struct Collectible {
        uint256 price; // in usd
    }

    IERC1155Collectible public immutable collection;
    address public immutable vesting;
    address public immutable refRegistry;

    address public baseStablecoin;
    bool public salesEnabled;

    uint256 public minBuy = 1e18;

    // @dev collections - list of resolved for sell stablecoins
    mapping(address => Token) public tokenInfo;
    // token id -> data
    mapping(uint256 => Collectible) public collectibleInfo;

    event Bought(address token, address from, uint256 tokenId, uint256 amount);
    event Deposited(address token, address from, uint256 amount);

    // `_collectionToken` - erc1155 token
    constructor(
        IERC1155Collectible _collectionToken,
        address _vesting,
        address _refRegistry,
        IUniV2PriceOracle _priceOracle
    ) {
        require(
            address(_collectionToken) != address(0) &&
            address(_vesting) != address(0) &&
            address(_refRegistry) != address(0) &&
            address(_priceOracle) != address(0),
            "Token sell: wrong constructor arguments"
        );

        collection = _collectionToken;
        vesting = _vesting;
        refRegistry = _refRegistry;

        Token storage token = tokenInfo[address(0)];
        token.resolved = true;
        token.price = 1e18;
        token.priceOracle = _priceOracle;

        collectibleInfo[1].price = 1e18;
        collectibleInfo[2].price = 769e14;
        collectibleInfo[3].price = 336e13;
        collectibleInfo[4].price = 541e12;
        collectibleInfo[5].price = 2086e10;
    }

    function buy(
        uint256 _amount,
        uint256 _tokenId,
        uint256 _items,
        address _to,
        address _sponsor
    ) external payable isSellApproved {
        require(_to != address(0), "Token sell: buy for vitalik?");
        require(_items > 0, "Token sell: zero items, really?");
        require(
            tokenInfo[address(0)].resolved,
            "Token sell: token is not accepted"
        );

        if (!IPartner(refRegistry).isUser(msg.sender)) {
            IPartner(refRegistry).register(msg.sender, _sponsor);
        }

        _buy(address(0), _amount, _tokenId, _items, _to);
    }

    function sellSwitcher(bool _status) external onlyOwner {
        salesEnabled = _status;
    }

    function setMinBuy(uint256 _minBuy) external onlyOwner {
        minBuy = _minBuy;
    }

    function setBaseStablecoin(address _stablecoin) external onlyOwner {
        baseStablecoin = _stablecoin;
    }

    function setPriceOracle(IUniV2PriceOracle _priceOracle) external onlyOwner {
        tokenInfo[address(0)].priceOracle = _priceOracle;
    }

    function countBuyAmount(
        address _token,
        uint256 _tokenId,
        uint256 _items
    ) public view returns (uint256 amountOut) {
        IUniV2PriceOracle priceOracle = tokenInfo[_token].priceOracle;
        address token0 = priceOracle.token0();
        address token1 = priceOracle.token1();
        uint256 amountIn = _items.mul(collectibleInfo[_tokenId].price);
        if (token0 == baseStablecoin) {
            amountOut = priceOracle.consult(token0, amountIn);
        } else {
            amountOut = priceOracle.consult(token1, amountIn);
        }
    }

    function _buy(
        address _token,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _items,
        address _to
    ) internal {
        uint256 minAmount = countBuyAmount(_token, _tokenId, _items);

        IUniV2PriceOracle priceOracle = IUniV2PriceOracle(
            tokenInfo[_token].priceOracle
        );
        // update price
        if (
            priceOracle.blockTimestampLast() + priceOracle.PERIOD() >=
            block.timestamp
        ) {
            priceOracle.update();
        }

        require(minAmount != 0, "Token sell: zero min amount");
        require(
            _amount >= minAmount,
            "Token sell: not enough to buy, low amount"
        );
        require(msg.value == _amount, "Token sell: not enough ether for buy");

        Address.sendValue(payable(vesting), _amount);
        collection.mint(_to, _tokenId, _items, "");
        emit Deposited(_token, msg.sender, _amount);
        emit Bought(_token, _to, _tokenId, _items);
    }

    modifier isSellApproved() {
        require(salesEnabled, "Sales disabled");
        _;
    }
}
