//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

/*
TrustlessNftPurchase
Allow two parties to transfer an NFT for a specified amount.
*/

contract TrustlessNftPurchase is Ownable {

    // IERC721Receiver private constant _ERC721Receiver = tnpReceiver;

    address payable public buyer;
    address payable public seller;

    uint public paymentAmount;
    bool public paymentAmountSet = false;
    bool public paymentSet = false;

    address public nftAddress;
    uint public nftId;

    uint public totalBuys = 0;

    bool public buyerSet = false;
    bool public sellerSet = false;
    bool public nftSet = false;

    uint public timeOfLock = 0;

    constructor() {
        buyer = payable(msg.sender);
        buyerSet = true;
    }

    modifier onlySeller() {
        require(seller == msg.sender, "caller is not the seller");
        _;
    }

    /** SELLER FUNCTIONS **/

    /**
    @dev Allow the seller to set the price buyer should pay
    @param _paymentAmount payment amount for NFT in ETH
     */
    function setPaymentAmount(uint _paymentAmount) external onlySeller {
        require(!paymentAmountSet, "paymentAmount already set");
        paymentAmount = _paymentAmount * 1 ether;
        paymentAmountSet = true;
    }

    /**
    @dev Allow the seller to transfer the NFT to the contract
     */
    function transferNft() external onlySeller {
        require(sellerSet, "Seller is not Set");
        require(buyerSet, "Buyer is not set");
        require(paymentAmountSet, "Payment amount is not set");
        require(address(this).balance == paymentAmount, "Nothing to withdraw");
        // safeTransferFrom();
        totalBuys += 1;
    }

    /** OWNER FUNCTIONS **/

    /**
    @dev Allow the owner to set the payment amount
    Set the variable timeOfLock which will be the block number given the call to setPayment
     */
    function setPayment() external payable onlyOwner {
        require(buyerSet, "Buyer has not been set");
        require(sellerSet, "Seller has not been set");
        require(paymentAmountSet, "Payment amount has not been set");
        require(!paymentSet, "Payment already set");
        require(paymentAmount == msg.value, "Payment amount must be what seller set");
        require(msg.value > 0, "Payment can not be 0");
        paymentSet = true;
        timeOfLock = block.number;
    }

    /**
    @dev Allow the owner to set the NFT
    @param _tokenAddress address of the NFT to be purchased
    @param _tokenId token id of the NFT to be purchased
     */
    function setNft(address _tokenAddress, uint256 _tokenId) public onlyOwner {
        require(_tokenAddress != address(0), "Token Address can not be 0");
        nftAddress = _tokenAddress;
        nftId = _tokenId;
        nftSet = true;
    }

    /**
    @dev Allow owner to set the buyer address
    @param _buyer address for the buyer
     */
    function setBuyer(address _buyer) external onlyOwner {
        require(!buyerSet, "Buyer already set");
        require(_buyer != address(0), "Invalid Address");
        buyer = payable(_buyer);
        buyerSet = true;
    }

    /**
    @dev Allow the owner to set the seller of the NFT
    @param _seller address for the seller
    - The seller address needs to be set so the seller address is able to transfer the NFT to the contract
     */
    function setSeller(address _seller) external onlyOwner {
        require(!sellerSet, "Seller already set");
        require(_seller != address(0), "Invalid Address");
        seller = payable(_seller);
        sellerSet = true;
    }

    /**
    @dev Allow the owner to reset the purchase values
     */
    function resetPurchase() external onlyOwner {
        buyerSet = false;
        sellerSet = false;
        paymentAmountSet = false;
    }

    /**
    @dev Allow the owner to withdraw funds from the contract
    The owner can withdraw funds if the seller fails to finish transaction
     */
    function withdraw() external onlyOwner {
        require(!buyerSet, "Buyer is Set");
        require(!sellerSet, "Seller is Set");
        require(address(this).balance != 0, "Nothing to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

}