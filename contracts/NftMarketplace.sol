//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./subscription.sol";
import "./profile.sol";

contract NftMarketplace is  ERC721URIStorage {
    

    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    Counters.Counter private nftsAvailableForSale;
    Counters.Counter private userIds;

    constructor() ERC721("NFT Magazine Subscription", "MAG") {
        tokenIds.increment();
        userIds.increment();
    }

    struct nftStruct {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        address[] subscribers;
        uint256 likes;
        string title;
        string description;
        string tokenUri;
    }
   
    mapping(uint256 => nftStruct) private nfts;


    event NftStructCreated(
        uint256 indexed tokenId,
        address payable seller,
        address payable owner,
        uint256 price,
        address[] subscribers,
        uint256 likes,
        string title,
        string description
    );

    //nftStruct[] public nftSubscriptions;

    function setNft(
        uint256 _tokenId,
        string memory _title,
        string memory _description,
        string memory _tokenURI
    ) private {

        nfts[_tokenId].tokenId = _tokenId;
        nfts[_tokenId].seller = payable(msg.sender);
        nfts[_tokenId].owner = payable(msg.sender);
        nfts[_tokenId].price = 0;
        nfts[_tokenId].likes = 1;
        nfts[_tokenId].title = _title;
        nfts[_tokenId].description = _description;
        nfts[_tokenId].tokenUri = _tokenURI;


        emit NftStructCreated(
            _tokenId,
            payable(msg.sender),
            payable(msg.sender),
            0,
            nfts[_tokenId].subscribers,
            nfts[_tokenId].likes,
            _title,
            _description
        );
    }

    /// @dev this function mints received NFTs
    /// @param _tokenURI the new token URI for the magazine cover
    /// @param _title the name of the magazine cover
    /// @param _description detailed information on the magazine NFT
    // /// @return tokenId of the created NFT
    function createNft(
        string memory _tokenURI,
        string memory _title,
        string memory _description
    ) public  {
        
        uint256 newTokenId = tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        setNft(newTokenId, _title, _description, _tokenURI);
        tokenIds.increment();
    }

    /// @dev sell a magazine subscription to the public so that's visible to the nft marketplace
    /// @param _tokenId the TokenID od the Nft Magazine
    // /// @param _price the price for the magazine subscription
    // /// @return total number of available nft subscriptions
    function sellSubscription(
        uint256 _tokenId, uint64 duration
    ) public payable returns (uint256) {
        require(
            _isApprovedOrOwner(msg.sender, _tokenId),
            "Only NFT owner can perform this"
        );
        _transfer(msg.sender, address(this), _tokenId);
        nfts[_tokenId].price = msg.value / (1 ether);
        nfts[_tokenId].owner = payable(address(this));
        //_expirations[_tokenId] = duration;
        nftsAvailableForSale.increment();
        return nftsAvailableForSale.current();
    }

    /// @dev buy a magazine subscription from the marketplace
    /// @param _tokenId the Token ID of the NFT Magazine
    /// @return true
    function buySubscription(uint256 _tokenId) public payable returns (bool) {
        // uint256 price = nfts[_tokenId].price;
        // require(
        //     msg.value == price,
        //     "Please send the asking price in order to complete the purchase"
        // );

        payable(nfts[_tokenId].seller).transfer(msg.value);
        nfts[_tokenId].subscribers.push(msg.sender);
        return true;
    }

    /// @dev fetch available NFTs on sale that will be displayed on the marketplace
    /// return nftStruct[] list of nfts with their metadata
    function getSubscriptions() public view returns (nftStruct[] memory) {
        uint256 nftCount = tokenIds.current();
        nftStruct[] memory nftSubs = new nftStruct[](nftCount);
        for (uint256 i = 1; i < nftCount; i++) {
            if (nfts[i].owner == address(this)) {
                nftSubs[i] = nfts[i];
            }
        }
        return nftSubs;
    }

    /// @dev fetches NFT magazines that a specific user is already subscribed to
    /// return nftStruct[] list of the nfts collected by a user with their metadata
    function getCollectables() public view returns (nftStruct[] memory) {
        uint256 nftCount = tokenIds.current();
        nftStruct[] memory nftSubs = new nftStruct[](nftCount);

        for (uint256 i = 1; i < nftCount; i++) {
            uint256 subscribers = nfts[i].subscribers.length;
            for (uint256 j = 0; j < subscribers; j++) {
                if (nfts[i].subscribers[j] == msg.sender) {
                    nftSubs[i] = nfts[i];
                }
            }
        }

        return nftSubs;
    }

    /// @dev fetches NFT magazines that a specific user has created
    ///@return nftStruct[] list of nfts created by a user with their metadata
    function getNfts() public view returns (nftStruct[] memory) {
        uint256 nftCount = tokenIds.current();
        nftStruct[] memory nftSubs = new nftStruct[](nftCount);
        for (uint256 i = 1; i < nftCount; i++) {
            if (nfts[i].seller == payable(msg.sender)) {
                nftSubs[i] = nfts[i];
            }
        }

        return nftSubs;
    }

    /// @dev fetches details of a particular NFT magazine subscription
    /// @param _tokenId The token ID of the NFT Magazine
    /// @return nftStruct NFT data of the specific token ID
    function getIndividualNFT(
        uint256 _tokenId
    ) public view returns (nftStruct memory) {
        return nfts[_tokenId];
    }


    /// @dev increments number of likes for a NFT Magazine by 1
    /// @param _tokenId the Token ID of the NFT Magazine
    function likeSubscription(uint256 _tokenId) public {
        nfts[_tokenId].likes += 1;
    }

    /// @dev decrement number of likes for a NFT Magazine by 1
    /// @param _tokenId the Token ID of the NFT Magazine
    function unlikeSubscription(uint256 _tokenId) public {
        nfts[_tokenId].likes -= 1;
    }
}
