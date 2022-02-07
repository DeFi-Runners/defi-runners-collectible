// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IERC1155Collectible.sol";
import "../Whitelist.sol";

abstract contract SalesPartners {
    mapping(address => address) public inviteBy;
    mapping(address => uint256) public raisedBalances;

    function _handlePartnersSale(address _partner, uint256 _amount) internal {
        if (_partner != address(0)) {
            require(_partner != msg.sender, "Sender address duplicate");
            require(
                inviteBy[_partner] != msg.sender,
                "Inverse relation is not possible"
            );

            if (inviteBy[msg.sender] == address(0)) {
                inviteBy[msg.sender] = _partner;
            }

            raisedBalances[_partner] += (_amount * 5) / 100; // 5%
        }
    }
}

contract DeFiRunnersBoxMarket is
    Whitelist,
    ReentrancyGuard,
    ERC1155Holder,
    SalesPartners
{
    enum SalesStatus {
        DISABLED,
        PRESALE,
        SALE
    }

    SalesStatus public status;

    address payable public fund;
    address public nft;

    uint256 public constant MAX_BOXES = 3;
    uint256 public maxTokenPurchase = 20;
    uint256[MAX_BOXES] public prices;

    event StatusSet(SalesStatus status);
    event PriceSet(uint256 tokenId, uint256 price);
    event BasicCollectionSet(address nft);
    event FundSet(address fund);

    constructor(
        IERC1155 _nft,
        uint256[MAX_BOXES] memory _prices,
        address payable _fund
    ) {
        require(
            address(_nft) != address(0) && address(_fund) != address(0),
            "Unacceptable address set"
        );

        for (uint256 i; i < MAX_BOXES; i++) {
            prices[i] = _prices[i];
        }

        nft = address(_nft);
        fund = _fund;
    }

    function mint(
        uint256 _boxId,
        uint256 _amount,
        address _partner
    )
        external
        payable
        isStatus(SalesStatus.SALE)
        isCorrectTokenId(_boxId)
        isCorrectAmount(_amount)
        nonReentrant
    {
        _handlePartnersSale(_partner, _amount);
        _buy(msg.sender, _boxId, _amount, msg.value);
    }

    function mintPresale(
        uint256 _boxId,
        uint256 _amount,
        address _partner
    )
        external
        payable
        isStatus(SalesStatus.PRESALE)
        isCorrectTokenId(_boxId)
        isCorrectAmount(_amount)
        isNotClaimed
        onlyMember
        nonReentrant
    {
        require(_boxId == 0, "Only small boxes");

        claimed[msg.sender] = true;
        _handlePartnersSale(_partner, _amount);
        _buy(msg.sender, _boxId, _amount, msg.value);
    }

    function setFund(address payable _newFund) external onlyOwner {
        require(
            _newFund != address(0) && _newFund != address(this),
            "Unacceptable address set"
        );

        fund = _newFund;
        emit FundSet(_newFund);
    }

    function setPrice(uint256 _tokenId, uint256 _price) external onlyOwner {
        prices[_tokenId] = _price;
        emit PriceSet(_tokenId, _price);
    }

    function setStatus(SalesStatus _status) external onlyOwner {
        status = _status;
        emit StatusSet(_status);
    }

    function withdrawNFTs(
        IERC1155 _token,
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external onlyOwner {
        _token.safeBatchTransferFrom(
            address(this),
            _to,
            _tokenIds,
            _amounts,
            ""
        );
    }

    function _buy(
        address _buyer,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _deposit
    ) internal {
        require(
            prices[_tokenId] * _amount == _deposit,
            "Market: ether value sent is not correct"
        );

        Address.sendValue(fund, _deposit);
        IERC1155(nft).safeTransferFrom(address(this), _buyer, _tokenId, _amount, "0x");
    }

    modifier isCorrectAmount(uint256 _amount) {
        require(
            _amount != 0 && _amount <= maxTokenPurchase,
            "Market: invalid amount"
        );
        _;
    }

    modifier isCorrectTokenId(uint256 _tokenId) {
        require(_tokenId < MAX_BOXES, "Market: invalid token id");
        _;
    }

    modifier isStatus(SalesStatus _status) {
        require(status == _status, "Market: incorrect status");
        _;
    }
}
