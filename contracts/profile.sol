//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";


contract ProfileModel {

    using Counters for Counters.Counter;
    Counters.Counter private userIds;
    
    constructor() {
       userIds.increment();
    }
    

    struct profileStruct {
        address self;
        address[] followers;
        address[] following;
    }

    mapping(uint256 => profileStruct) public profiles;

    function getNumberOfUsers() public view returns(uint256){
        uint256 noOfUsers = userIds.current();
        return noOfUsers;
    }

    ///@notice this respresents user onboarding
    /// @dev adds msg.sender as the profile
    // /// @return userId and balance of msg.sender
    function addProfile() public { // returns (uint256 userId, uint256 balance) {
        uint256 newUserId = userIds.current();
        bool checkIfExists = false;
        for (uint256 i = 1; i < newUserId; i++) {
            if (profiles[i].self == msg.sender)
            checkIfExists = true;
        }

        if(!checkIfExists) {
        profiles[newUserId].self = msg.sender;
        }
        // userId = newUserId;
        // balance = msg.sender.balance;
        userIds.increment();
    }
    
    // ///@notice this respresents user onboarding
    // /// @dev get profile of a specific user
    // // /// @return profile struct
    // function getProfile() public view returns(profileStruct memory) { // returns (uint256 userId, uint256 balance) {
    //     uint256 userCount = userIds.current();
    //     profileStruct memory profile;
    //     for (uint256 i = 1; i < userCount; i++) {
    //             if (profiles[i].self == msg.sender) {
    //                 profile = profiles[i];
    //             }   
    //     }
    //     return profile;
    // }


    /// @dev increment the following tag of the profile performing the action, and the follower tag of the profile that user wants to follow
    /// @param _account The account the user wants to follow
    function followProfile(address _account) public {
        console.log(_account);
        console.log(msg.sender);
        uint256 totalCount = userIds.current();
        console.log(totalCount);
        for (uint256 i = 1; i < totalCount; i++) {
            console.log(profiles[i].self);

            if (profiles[i].self == msg.sender) {
                //console.log("yes");
                profiles[i].following.push(_account);
                
                console.log(profiles[i].following.length);
            }
            else if (profiles[i].self == _account) {
                profiles[i].followers.push(msg.sender);
            }
            console.log(profiles[i].self);
            console.log(profiles[i].following.length);
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
}