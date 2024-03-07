// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ConfirmedOwner} from "@chainlink/contracts@0.8.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import {VRFV2WrapperConsumerBase} from "@chainlink/contracts@0.8.0/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {LinkTokenInterface} from "@chainlink/contracts@0.8.0/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

import "./lottery.sol";

contract RandomNumber is ConfirmedOwner, VRFV2WrapperConsumerBase {

    address constant linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant wrapper = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    lottery public immutable deployerParent;
    address public immutable creator;
    

    uint32 constant callbackGasLimit = 100000;
    uint16 constant requestConfirmations = 1;
    uint32 constant numWords = 3;

    uint256[] requestIds;

    struct randomNumbers {
        uint256 requestID;
        uint256[] prizes;
        uint[] numbers;
        bool fulfilled;
    }

    mapping(uint256=>randomNumbers) requestIdToNumbers;

    constructor(address _creator)
    ConfirmedOwner(msg.sender)
    VRFV2WrapperConsumerBase(linkAddress, wrapper)
    {
        deployerParent = lottery(payable(msg.sender));
        creator = _creator;
    }

    function requestRandomWords(uint256 one, uint256 two, uint256 three) external onlyOwner returns (uint256) {
        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        requestIds.push(requestId);
        requestIdToNumbers[requestId].requestID = requestId;
        requestIdToNumbers[requestId].prizes = [one, two, three];
        requestIdToNumbers[requestId].fulfilled = false;
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        requestIdToNumbers[_requestId].fulfilled = true;
        requestIdToNumbers[_requestId].numbers = _randomWords;
        deployerParent.gotRandomWords(_randomWords, requestIdToNumbers[_requestId].prizes);
    }

    function withdrawLink() external _onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(creator, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function withdrawETH() public _onlyOwner {
        (bool sent, ) = payable(creator).call{
            value: address(this).balance
        }("");
        require(sent, "Failed");
    }

    modifier _onlyOwner () {
        require(msg.sender == address(deployerParent), "Not Owner. Not Allowed");
        _;
    }

}