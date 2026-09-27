// SPDX-License-Identifier: MIT
pragma solidity ^0.8.37;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTAssetStore is ERC721URIStorage, Ownable {

    uint256 private nextTokenId = 1;

    struct DigitalAsset {
        uint256 tokenId;
        string title;
        string metadataURI;
        string rarity;
        string traits;
        uint256 initialPrice;
        uint256 sellingPrice;
        address creator;
        bool forSale;
    }

    mapping(uint256 => DigitalAsset) public digitalAssets;

    event AssetMinted(uint256 indexed tokenId,address indexed creator, string title, uint256 initialPrice );
    event AssetListed(uint256 indexed tokenId, uint256 sellingPrice );
    event AssetRemovedFromSale(uint256 indexed tokenId);
    event AssetSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 sellingPrice);

    constructor() ERC721("NFT Asset Store", "NAS") Ownable(msg.sender) {}

    // Create and mint a new ERC-721 NFT
    function createAsset(string memory title, string memory metadataURI, string memory rarity, string memory traits, uint256 initialPrice ) public {

        require(initialPrice > 0, "Price must be greater than zero");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataURI);

        digitalAssets[tokenId] = DigitalAsset({
            tokenId: tokenId,
            title: title,
            metadataURI: metadataURI,
            rarity: rarity,
            traits: traits,
            initialPrice: initialPrice,
            sellingPrice: initialPrice,
            creator: msg.sender, forSale: false });

        emit AssetMinted(tokenId, msg.sender, title, initialPrice );
    }

    // Put an owned NFT on sale
    function putForSale(uint256 tokenId, uint256 sellingPrice ) public {

        require(ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(sellingPrice > 0, "Price must be greater than zero");

        digitalAssets[tokenId].sellingPrice = sellingPrice;
        digitalAssets[tokenId].forSale = true;
        emit AssetListed(tokenId, sellingPrice);
    }

    // Remove an NFT from sale
    function removeFromSale(uint256 tokenId ) public {

        require(ownerOf(tokenId) == msg.sender, "You are not the owner" );
        require(digitalAssets[tokenId].forSale, "Asset is not for sale");

        digitalAssets[tokenId].forSale = false;
        emit AssetRemovedFromSale(tokenId);
    }

    // Buy a listed NFT
    function purchaseAsset(uint256 tokenId ) public payable {

        DigitalAsset storage asset = digitalAssets[tokenId];

        require( asset.forSale, "Asset is not for sale" );
        require(msg.value == asset.sellingPrice, "Incorrect payment amount" );

        address seller = ownerOf(tokenId);

        require( seller != msg.sender, "You already own this asset");

        asset.forSale = false;
        _safeTransfer( seller, msg.sender, tokenId, "");
        // payable(seller).transfer(msg.value);
        (bool success, ) = payable(seller).call{value: msg.value}("");
        require(success, "Payment failed");
        emit AssetSold( tokenId, seller, msg.sender, msg.value );
    }

    // Return all stored information about an NFT
    function getAssetDetails( uint256 tokenId ) public view returns (DigitalAsset memory)
    {
        require(digitalAssets[tokenId].tokenId != 0, "Asset does not exist");
        return digitalAssets[tokenId];
    }

    // Number of NFTs created
    function totalAssets() public view returns (uint256)
    {
        return nextTokenId - 1;
    }
}