// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import  { AssetData, Assetdetails } from "./libAssetData.sol";
import "./libAssetpricing.sol";
import "../../lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol/";
import "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol/";

library libAssetbuyer {

event AssetPurchased(address _buyer, int price);
event AssetStaged(address _owner, string category);
    function _stageAsset(
        string memory assetName,
        uint256 assetPrice,
        address assetOwner,
        address assetAddress,
        bool isNFT,
        uint erc20value,
        uint256 _nftId
    ) internal {
        AssetData storage assetData = AssetSlot();
        assetData.assetId++;
        uint256 assetId = assetData.assetId;
        string memory newcategory;
        if(isNFT){

            newcategory = assetData.Assetdetail[assetId].AssetCategory;
            newcategory = "ERC721";
        }else{
            newcategory = assetData.Assetdetail[assetId].AssetCategory;
            newcategory = "ERC20";
        }
        assetOwner = msg.sender;
        assetData.Assetdetail[assetId] = Assetdetails({
            AssetName: assetName,
            AssetPrice: assetPrice,
            Assetowner: assetOwner,
            AssetAddress: assetAddress,
            Assetpurchased: false,
            buyer: address(0),
            AssetCategory: newcategory,
            nftId: _nftId,
            isNFT: isNFT
        });
        if (isNFT){
           IERC721(assetAddress).approve(address(this), _nftId);

        }else{
            IERC20(assetAddress).approve(address(this), erc20value);
        }
        

        emit AssetStaged(msg.sender, newcategory);
    }

    function buyAsset(uint256 _assetid, string memory paymentToken) internal {
        AssetData storage assetData = AssetSlot();
        require(assetData.Assetdetail[_assetid].Assetpurchased==false, "Asset purchased");
        int price  = Assetpricing.calcPriceInToken(paymentToken, _assetid);
        IERC20 paymentTokenadd = IERC20(assetData.paymentmethod[paymentToken].paymentTokenAddress);
        uint256 balance = paymentTokenadd.balanceOf(msg.sender);
        require(balance >= uint256(price), "Insufficient balance");
       address assetaddress =  assetData.Assetdetail[_assetid].AssetAddress;
       address assetowner =  assetData.Assetdetail[_assetid].Assetowner;
        paymentTokenadd.approve(address(this), uint256(price));
       uint nftid =  assetData.Assetdetail[_assetid].nftId;
        if ((assetData.Assetdetail[_assetid].isNFT)==false) {
           bool success = IERC20(assetaddress).transferFrom(assetowner, msg.sender, uint256(price));
           require(success, "asset unavailable try again");
        }
        else{
           IERC721(assetaddress).transferFrom(assetowner, msg.sender, nftid);
        }
        paymentTokenadd.transferFrom(msg.sender, address(this), uint256(price));
        assetData.Assetdetail[_assetid].Assetpurchased = true;
        assetData.Assetdetail[_assetid].buyer = msg.sender;
        emit AssetPurchased(msg.sender, price);
    }



 function getAssetDetails(uint256 assetId) internal view returns (Assetdetails memory) {
        AssetData storage assetData = AssetSlot();
        require(assetData.Assetdetail[assetId].AssetAddress != address(0), "Asset does not exist");
        return assetData.Assetdetail[assetId];
    }

  function isAssetPurchased(uint256 assetId) public view returns (bool) {
        AssetData storage assetData = AssetSlot();
        require(assetData.Assetdetail[assetId].AssetAddress != address(0), "Asset does not exist");
        return assetData.Assetdetail[assetId].Assetpurchased;
    }


        function withdraweth(uint256 _value) internal returns (bool success) {
            // AssetData storage ds = AssetSlot();
     require(address(this).balance >= _value, "insufficient balance");
     address payable reciepient = payable(msg.sender);
     success = reciepient.send(_value);
     require(success, "withdrawal failed");
    }

    function withdrawERC20token(address _tokenaddress) internal returns (bool success) {
            // AssetData storage ds = AssetSlot();
            uint amt = IERC20(_tokenaddress).balanceOf(address(this));
            require(amt > 0, "insuficient balance");
            success = IERC20(_tokenaddress).transfer(msg.sender, amt);
            return success;
      }
    function withdrawERC721token(address _tokenaddress, uint _tokenid) internal returns (bool success) {
        // AssetData storage ds = AssetSlot();
        address owner = IERC721(_tokenaddress).ownerOf(_tokenid);
        require(owner==address(this), "token not available");
        IERC721(_tokenaddress).transferFrom(address(this), msg.sender, _tokenid);
        success = true;
        return success;
    }


    function AssetSlot() internal pure returns(AssetData storage ds) {
        assembly {
            ds.slot := 0
        }
      }
}