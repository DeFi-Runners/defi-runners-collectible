// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <1.0.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// ERC1155 prices sales contract
contract NFTBoxSales is ERC1155Holder, Ownable {
    using SafeMath for uint256;

    enum SalesStatus {
        DISABLED,
        ENABLED
    }

    SalesStatus public status;

    uint256 public constant MAX_BOXES = 3;

    address payable public fund;
    uint256 public maxTokenPurchase = 20;

    IERC1155 public nft;

    uint256[MAX_BOXES] public prices;

    event StatusSet(SalesStatus status);
    event PurchaseSet(uint256 amount);
    event BasicCollectionSet(address nft);
    event FundSet(address fund);

    constructor(
        IERC1155 _nft,
        uint256[MAX_BOXES] memory _prices,
        address payable _fund
    ) {
        require(address(_nft) != address(0), "Unacceptable address set");

        for (uint256 i; i < MAX_BOXES; i++) {
            prices[i] = _prices[i];
        }

        nft = _nft;
        fund = _fund;

        emit StatusSet(SalesStatus.DISABLED);
        emit PurchaseSet(maxTokenPurchase);
        emit BasicCollectionSet(address(_nft));
        emit FundSet(_fund);
    }

    receive() external payable isSalesActive {
        uint256 boxId = 2;
        _buy(msg.value / prices[boxId], boxId, msg.value);
    }

    function buy(uint256 _amount, uint256 _boxId)
        external
        payable
        isSalesActive
    {
        _buy(_amount, _boxId, msg.value);
    }

    function _buy(
        uint256 _amount,
        uint256 _boxId,
        uint256 _deposit
    ) internal {
        require(_boxId < MAX_BOXES, "Market: box id not exist");
        require(
            _amount != 0 && _amount <= maxTokenPurchase,
            "Market: invalid amount set, to much or too low"
        );

        require(
            prices[_boxId].mul(_amount) == _deposit,
            "Market: ether value sent is not correct"
        );

        Address.sendValue(fund, _deposit);

        nft.safeTransferFrom(address(this), msg.sender, _boxId, _amount, "");
    }

    function statusSwitcher() external onlyOwner {
        if (SalesStatus.ENABLED == status) {
            status = SalesStatus.DISABLED;
        } else {
            status = SalesStatus.ENABLED;
        }

        emit StatusSet(status);
    }

    function setTokenPurchase(uint256 _amount) external onlyOwner {
        require(_amount != 0, "Invalid value");

        maxTokenPurchase = _amount;
        emit PurchaseSet(_amount);
    }

    function changeBasicCollection(IERC1155 _newNft) external onlyOwner {
        nft = _newNft;
        emit BasicCollectionSet(address(_newNft));
    }

    function setFund(address payable _newFund) external onlyOwner {
        require(
            _newFund != address(0) && _newFund != address(this),
            "Zero address set"
        );

        fund = _newFund;
        emit FundSet(_newFund);
    }

    function withdraw(
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

    modifier isSalesActive() {
        require(SalesStatus.ENABLED == status, "Market: sale is not active");
        _;
    }
}
