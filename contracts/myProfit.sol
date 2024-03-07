// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract myProfit {

    address public immutable creatorContract;
    address immutable creator;

    constructor(address _creator) {
        creatorContract = msg.sender;
        creator = _creator;
    }

    function withdrawMyProfit() public onlyOwner payable {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        require(msg.sender == creatorContract, "Not Allowed! You are not the owner");
        _;
    }
}