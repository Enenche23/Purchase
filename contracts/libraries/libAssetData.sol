// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct Assetdetails {
    string AssetName;
    uint256 AssetPrice;
    address Assetowner;
    address AssetAddress;
    bool Assetpurchased;
    address buyer;
    string AssetCategory;
    uint256 nftId;
    bool isNFT;
}
struct payment {
    address paymentTokenfeed;
    int price;
    address paymentTokenAddress;

}

struct AssetData {
    uint256 assetId;
    mapping (uint256 => Assetdetails) Assetdetail;
    string[] paymentmethods;
    mapping (string => payment) paymentmethod;

}
