//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract SubscriptionModel {
    mapping(uint256 => uint64) internal _expirations;

    /// @notice Emitted when a subscription expiration changes
    /// @dev When a subscription is canceled, the expiration value should also be 0.
    event SubscriptionUpdate(uint256 indexed tokenId, uint64 expiration);

    /// @notice Renews the subscription to an NFT
    /// Throws if `tokenId` is not a valid NFT
    /// @param _tokenId The NFT to renew the subscription for
    /// @param duration The number of seconds to extend a subscription for
    function renewSubscription(
        uint256 _tokenId,
        uint64 duration
    ) external payable {
        uint64 currentExpiration = _expirations[_tokenId];
        uint64 newExpiration;
        if (currentExpiration == 0) {
            //block.timestamp -> Current block timestamp as seconds since unix epoch
            newExpiration = uint64(block.timestamp) + duration;
        } else {
            require(isRenewable(_tokenId), "Subscription Not Renewable");
            newExpiration = currentExpiration + duration;
        }
        _expirations[_tokenId] = newExpiration;
        emit SubscriptionUpdate(_tokenId, newExpiration);
    }

    // /// @notice Cancels the subscription of an NFT
    // /// @dev Throws if `tokenId` is not a valid NFT
    // /// @param _tokenId The NFT to cancel the subscription for
    function cancelSubscription(uint256 _tokenId) external payable {
        delete _expirations[_tokenId];
        emit SubscriptionUpdate(_tokenId, 0);
    }

    // /// @notice Gets the expiration date of a subscription
    // /// @dev Throws if `tokenId` is not a valid NFT
    // /// @param _tokenId The NFT to get the expiration date of
    // /// @return The expiration date of the subscription
    function expiresAt(uint256 _tokenId) external view returns (uint64) {
        return _expirations[_tokenId];
    }

    // /// @notice Determines whether a subscription can be renewed
    // /// @dev Throws if `tokenId` is not a valid NFT
    // /// @param _tokenId The NFT to get the expiration date of
    // /// @return The renewability of a the subscription - true or false
    function isRenewable(uint256 tokenId) public pure returns (bool) {
        return true;
    }
}

contract NftMarketplace is SubscriptionModel, ERC721URIStorage {
    

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
    struct profileStruct {
        address self;
        address[] followers;
        address[] following;
    }
    mapping(uint256 => nftStruct) private nfts;
    mapping(uint256 => profileStruct) public profiles;

    function getNumberOfUsers() public view returns(uint256){
        uint256 noOfUsers = userIds.current();
        return noOfUsers;
    }

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
        uint256 _tokenId
    ) public payable returns (uint256) {
        require(
            _isApprovedOrOwner(msg.sender, _tokenId),
            "Only NFT owner can perform this"
        );
        _transfer(msg.sender, address(this), _tokenId);
        nfts[_tokenId].price = msg.value / (1 ether);
        nfts[_tokenId].owner = payable(address(this));
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

    ///@notice this respresents user onboarding
    /// @dev adds msg.sender as the profile
    function addProfile() public {
        uint256 newUserId = userIds.current();
        bool checkIfExists = false;
        for(uint256 i = 1; i < newUserId; i++) {
            if(profiles[i].self == msg.sender)
            checkIfExists = true;
        }
        if(!checkIfExists) {
            profiles[newUserId].self = msg.sender;
        }
        userIds.increment();
    }

    /// @dev increment the following tag of the profile performing the action, and the follower tag of the profile that user wants to follow
    /// @param _account The account the user wants to follow
    function followProfile(address _account) public {
        uint256 totalCount = userIds.current();
        for (uint256 i = 1; i < totalCount; i++) {
            if (profiles[i].self == payable(msg.sender)) {
                profiles[i].following.push(payable(_account));
            }
            if (profiles[i].self == _account) {
                profiles[i].followers.push(payable(msg.sender));
            }
        }
    }

    /// @dev decrement the following tag of the profile performing the action, and the follower tag of the profile that the user to unfollow
    /// @param _account The account the user wants to unfollow
    function unfollowProfile(address _account) public view {
        uint256 totalCount = userIds.current();
        for (uint256 i = 1; i < totalCount; i++) {
            removeFollowing(profiles[i].self, profiles[i].followers, _account);
            removeFollower(
                profiles[i].self,
                profiles[i].following,
                payable(msg.sender)
            );
        }
    }

    function removeFollowing(
        address _owner,
        address[] memory _followers,
        address _account
    ) private view {
        if (_owner == _account) {
            address[] memory currentFollowing = _followers;
            for (uint256 j = 0; j < currentFollowing.length; j++) {
                if (currentFollowing[j] == payable(msg.sender)) {
                    delete currentFollowing[j];
                }
            }
        }
    }

    function removeFollower(
        address _owner,
        address[] memory _following,
        address _account
    ) private pure {
        if (_owner == _account) {
            address[] memory currentFollowers = _following;
            for (uint256 j = 0; j < currentFollowers.length; j++) {
                if (currentFollowers[j] == _account) {
                    delete currentFollowers[j];
                }
            }
        }
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
