// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./myProfit.sol";
import "./uintLibrary.sol";

import {LinkTokenInterface} from "@chainlink/contracts@0.8.0/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract lottery {

    using uintLibrary for uint256;

    uint256 constant MINIMUM_USD = 10 * 1e18;
    uint256 numberOfParticipants = 0;

    address public immutable creator;
    myProfit public immutable childContract;
    address[] public participants;
    mapping(address=>uint256) public addressToNumberOfTickets;
    mapping(address=>uint256) public addressToTip;

    uint32 numWords = 3;
    address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    constructor() {
        creator = msg.sender;
        childContract = new myProfit(creator);
    }

    function isNewBuyer(address buyer) internal view returns(bool) {
        uint256 length = participants.length;
        bool found = false;
        for(uint256 i = 0; i < length; i++) {
            address addressAtIndex = participants[i];
            if(addressAtIndex == buyer) found = true;
        }
        return found;
    }

    function buyTicket() public payable {
        require(msg.value.toUSD() > MINIMUM_USD, "Need to send more.");
        uint256 tip = msg.value.toUSD() % MINIMUM_USD;
        if(isNewBuyer(msg.sender)) {
            participants.push(msg.sender);
            addressToNumberOfTickets[msg.sender] = msg.value.toUSD() % MINIMUM_USD;
        } else {
            addressToNumberOfTickets[msg.sender] += msg.value.toUSD() % MINIMUM_USD;
        }
        if (tip > 0) {
            if(addressToTip[msg.sender] > 0) {
                addressToTip[msg.sender] += tip;
            } else {
                addressToTip[msg.sender] = tip;
            }
        }
    }

    function resetEverything() internal {
        uint256 length = participants.length;
        for(uint256 i = 0; i < length; i++) {
            addressToNumberOfTickets[participants[i]] = 0;
        }
        participants = new address[](0);
    }

    function distributeRewards() public onlyOwner {
        uint256 balanceInContract = address(this).balance;
        uint256 ownerReward = (balanceInContract * 5)/100;
        (bool sentToContract, ) = payable(address(childContract)).call{
            value: ownerReward
        }("");
        require(sentToContract, "Call Failed. Couldn't send to child contract.");
        uint256 firstPrize = (balanceInContract * 50) / 100;
        uint256 secondPrize = (balanceInContract * 30) / 100;
        uint256 thirdPrize = (balanceInContract * 10) / 100;
        // find winners send moni and done
        resetEverything();
    }

    function withdrawTip() public {
        require(addressToTip[msg.sender] > 0, "No Tip to withdraw!");
        (bool sent, ) = payable(msg.sender).call{
            value: (addressToTip[msg.sender] * 99) / 100
        }("");
        require(sent, "Failed");
        addressToTip[msg.sender] = 0;
    }

    function withdrawAllLinkFromContract() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function withdrawEverythingAlsoCalledRugLol() public onlyOwner {
        (bool sent, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(sent, "Failed");
    }

    modifier onlyOwner() {
        require(msg.sender == creator, "Not Allowed! You are not the owner");
        _;
    }

    receive() external payable {
        buyTicket();
    }

    fallback() external payable {
        buyTicket();
    }
}