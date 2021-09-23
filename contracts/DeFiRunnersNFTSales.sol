/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IERC1155Collectible.sol";
import "./Partners.sol";

contract DeFiRunnersNFTSales is ERC721Holder, Ownable, Partners {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Token {
        bool stablecoin;
        bool resolved;
        uint256 price; // todo в чем? in usd decimal 10^8
    }

    struct Collectible {
        uint256 price; // in usd // todo покупку делать за эту цену 10^8
    }

    IERC1155Collectible public collection;
    address public vesting;

    bool public salesEnabled;

    // @dev collections - list of resolved for sell stablecoins

    mapping(address => Token) public tokenInfo;
    // token id -> data
    mapping(uint256 => Collectible) public collectibleInfo;

    event Bought(address token, address from, uint256 tokenId, uint256 amount);
    event Deposited(address token, address from, uint256 amount);

    // `_collectionToken` - erc1155 token
    constructor(IERC1155Collectible _collectionToken, address _vesting) {
        collection = _collectionToken;
        vesting = _vesting;
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
        require(
            _items > 0,
            "Token sell: zero items, really?"
        );
        require(
            tokenInfo[_token].resolved,
            "Token sell: token is not accepted"
        );
        
        if (!isUser(msg.sender)) {
            _register(msg.sender, _sponsor);
        }

        if (_token != address(0)) {
            _buy(_token, _amount, _tokenId, _items, _to);
        } else {
            _buyETH(_token, _amount, _tokenId, _items, _to);
        }
    }

    function setToken(
        address _token,
        uint256 _price,
        bool _stablecoin,
        bool _resolved
    )
        external
        onlyOwner
    {
        if (!(_stablecoin && _resolved)) {
            delete tokenInfo[_token];
        } else {
            if (_resolved) {
                require(!tokenInfo[_token].resolved, "Token sell: token resolved");
            }

            if (!_stablecoin) {
                require(_price != 0, "Token sell: zero token price");

                tokenInfo[_token].price = _price;
            } else {
                tokenInfo[_token].price = 1e8; // 10^8
            }

            tokenInfo[_token].stablecoin = _stablecoin;
            tokenInfo[_token].resolved = _resolved;
        }
    }

    function sellSwitcher(bool _status) external onlyOwner {
        salesEnabled = _status;
    }

    function countBuyAmount(address _account, address buyToken, uint _tokenId, uint _amount)
        external
        view
        returns (uint price)
    {
        require(
            _amount > 0,
            "Token sell: zero items, really?"
        );
        require(
            tokenInfo[buyToken].resolved,
            "Token sell: token is not accepted"
        );

        price = _amount.mul(collectibleInfo[_tokenId].price);
    }

    function _buyETH(
        address _token,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _items,
        address _to
    ) internal {
        uint256 price = _items.mul(collectibleInfo[_tokenId].price);

        require(_amount >= price, "Token sell: not enough to buy, low amount");
        require(msg.value == _amount, "Token sell: not enough ether for buy");

        Address.sendValue(payable(vesting), _amount);
        collection.mint(_to, _tokenId, _items, "");
        emit Deposited(_token, msg.sender, _amount);
        emit Bought(_token, _to, _tokenId, _items);
    }

    function _buy(
        address _token,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _items,
        address _to
    ) internal {
        require(msg.value == 0, "Ether value not zero");

        uint256 price = _items.mul(collectibleInfo[_tokenId].price);

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
