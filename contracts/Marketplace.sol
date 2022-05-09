// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract Marketplace is Ownable, ReentrancyGuard, ERC1155Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIdCounter;
    Counters.Counter private _itemSoldCount;
    uint256 public itemOnsaleCount;
    address public feeWallet;
    uint256 public feeRate;
    uint256 public feeBasePoints = 10000;
    uint256 public lastFeeUpdate;

    struct MarketItem {
        uint256 itemId;
        address nftToken;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        address paymentToken;
        bool sold;
        bool isErc1155;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event FeeUpdated(
        uint256 oldFeeRate,
        uint256 newFeeRate,
        uint256 lastFeeUpdate
    );
    event ItemOnSale(
        uint256 itemId,
        address nftToken,
        uint256 tokenId,
        address seller,
        uint256 price,
        address paymentToken,
        bool isErc1155
    );
    event ItemSold(
        uint256 itemId,
        address nftToken,
        uint256 tokenId,
        address seller,
        address owner,
        uint256 price,
        address paymentToken,
        bool isErc1155
    );

    event ItemDelist(
        uint256 itemId,
        address nftToken,
        uint256 tokenId,
        address seller,
        uint256 price,
        address paymentToken,
        bool isErc1155
    );

    constructor(address _feeWallet, uint256 _feeRate) {
        require(
            _feeWallet != address(0),
            "Fee wallet cannot be the zero address"
        );

        feeWallet = _feeWallet;
        setFeeRate(_feeRate);
    }

    function setFeeWallet(address _feeWallet) public onlyOwner {
        require(
            _feeWallet != address(0),
            "Fee wallet cannot be the zero address"
        );
        feeWallet = _feeWallet;
    }

    function setFeeRate(uint256 _feeRate) public onlyOwner {
        require(
            _feeRate > 0 && _feeRate < feeBasePoints,
            "Fee rate must be greater than zero"
        );
        lastFeeUpdate = block.timestamp;
        emit FeeUpdated(feeRate, _feeRate, lastFeeUpdate);
        feeRate = _feeRate;
    }

    function calculateFee(uint256 _amount) internal view returns (uint256) {
        require(
            (_amount / feeBasePoints) * feeBasePoints == _amount,
            "Amount too small"
        );
        return (_amount * feeRate) / feeBasePoints;
    }

    function placeItemOnSale(
        bool _isErc1155,
        address _nftToken,
        uint256 _tokenId,
        uint256 _price,
        address _paymentToken
    ) public nonReentrant returns (bool) {
        address origin = _msgSender();
        require(
            _nftToken != address(0),
            "_nftToken cannot be the zero address"
        );
        require(_tokenId != 0, "_tokenId cannot be zero");
        require(_price != 0, "_price cannot be zero");

        _itemIdCounter.increment();
        uint256 _currentItemId = _itemIdCounter.current();
        itemOnsaleCount++;
        // add item to on sale list
        idToMarketItem[_currentItemId] = MarketItem(
            _currentItemId,
            _nftToken,
            _tokenId,
            payable(origin),
            payable(address(0)),
            _price,
            _paymentToken,
            false,
            _isErc1155
        );
        //transfer nft token to contract

        if (_isErc1155) {
            IERC1155(_nftToken).safeTransferFrom(
                origin,
                address(this),
                _tokenId,
                1,
                ""
            );
        } else {
            IERC721(_nftToken).safeTransferFrom(
                origin,
                address(this),
                _tokenId
            );
        }
        emit ItemOnSale(
            _currentItemId,
            _nftToken,
            _tokenId,
            origin,
            _price,
            _paymentToken,
            _isErc1155
        );
        return true;
    }

    function placeBatchItemOnSale(
        bool _isErc1155,
        address _nftToken,
        uint256[] memory _tokenId,
        uint256[] memory _price,
        address _paymentToken
    ) public nonReentrant returns(bool) {
        address origin = _msgSender();
        require(
            _nftToken != address(0),
            "_nftToken cannot be the zero address"
        );
        for(uint8 i = 0; i < _tokenId.length; i++) {
            require(_tokenId[i] != 0, "_tokenId cannot be zero");
            require(_price[i] != 0, "_price cannot be zero");

            _itemIdCounter.increment();
            uint256 _currentItemId = _itemIdCounter.current();
            itemOnsaleCount++;
            // add item to on sale list
            idToMarketItem[_currentItemId] = MarketItem(
                _currentItemId,
                _nftToken,
                _tokenId[i],
                payable(origin),
                payable(address(0)),
                _price[i],
                _paymentToken,
                false,
                _isErc1155
            );
            //transfer nft token to contract

            if (_isErc1155) {
                IERC1155(_nftToken).safeTransferFrom(
                    origin,
                    address(this),
                    _tokenId[i],
                    1,
                    ""
                );
            } else {
                IERC721(_nftToken).safeTransferFrom(
                    origin,
                    address(this),
                    _tokenId[i]
                );
            }
            emit ItemOnSale(
                _currentItemId,
                _nftToken,
                _tokenId[i],
                origin,
                _price[i],
                _paymentToken,
                _isErc1155
            );
        }
        return true;
    }

    function buyItem(uint256 _itemId) public nonReentrant {
        address origin = _msgSender();
        require(_itemId != 0, "_itemId cannot be zero");
        MarketItem storage item = idToMarketItem[_itemId];
        require(item.itemId != 0, "Item does not exist");
        require(item.sold == false, "Item is already sold");
        require(item.seller != origin, "You can't buy your own item");

        uint256 txFee = calculateFee(item.price);
        // pay for fee
        IERC20(item.paymentToken).transferFrom(origin, feeWallet, txFee);
        // pay for seller
        IERC20(item.paymentToken).transferFrom(
            origin,
            item.seller,
            item.price - txFee
        );

        item.sold = true;
        item.owner = payable(origin);
        // transfer token to buyer
        if (item.isErc1155) {
            IERC1155(item.nftToken).safeTransferFrom(
                address(this),
                origin,
                item.tokenId,
                1,
                ""
            );
        } else {
            IERC721(item.nftToken).safeTransferFrom(
                address(this),
                origin,
                item.tokenId
            );
        }
        _itemSoldCount.increment();
        emit ItemSold(
            item.itemId,
            item.nftToken,
            item.tokenId,
            item.seller,
            origin,
            item.price,
            item.paymentToken,
            item.isErc1155
        );
    }

    function getItemsOnSale() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIdCounter.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (
                idToMarketItem[i].sold == false &&
                idToMarketItem[i].seller != address(0)
            ) {
                itemCount++;
            }
        }

        MarketItem[] memory itemsOnSale = new MarketItem[](itemCount);
        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (
                idToMarketItem[i].sold == false &&
                idToMarketItem[i].seller != address(0)
            ) {
                itemsOnSale[currentIndex] = idToMarketItem[i];
                currentIndex++;
            }
        }
        return itemsOnSale;
    }

    function getMyItemsOnSale() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIdCounter.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (
                idToMarketItem[i].sold == false &&
                idToMarketItem[i].seller == _msgSender()
            ) {
                itemCount++;
            }
        }

        MarketItem[] memory myItemsOnSale = new MarketItem[](itemCount);
        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (
                idToMarketItem[i].sold == false &&
                idToMarketItem[i].seller == _msgSender()
            ) {
                myItemsOnSale[currentIndex] = idToMarketItem[i];
                currentIndex++;
            }
        }
        return myItemsOnSale;
    }

    function delistItem(uint256 _itemId) public {
        address origin = _msgSender();
        require(_itemId != 0, "_itemId cannot be zero");
        MarketItem memory item = idToMarketItem[_itemId];
        require(item.sold == false, "Item is already sold");
        require(item.seller == origin, "You can't delist this item");
        itemOnsaleCount--;
        if (item.isErc1155) {
            IERC1155(item.nftToken).safeTransferFrom(
                address(this),
                item.seller,
                item.tokenId,
                1,
                ""
            );
        } else {
            IERC721(item.nftToken).safeTransferFrom(
                address(this),
                item.seller,
                item.tokenId
            );
        }
        emit ItemDelist(
            item.itemId,
            item.nftToken,
            item.tokenId,
            item.seller,
            item.price,
            item.paymentToken,
            item.isErc1155
        );
        delete idToMarketItem[_itemId];
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
