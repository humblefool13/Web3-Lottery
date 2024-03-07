// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library uintLibrary {
        function getPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer*1e10);
    }

    function toUSD(uint256 ethAmount)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(); // 1 e 18
        uint amountInUSD = (ethPrice * ethAmount) / 1e18;
        return amountInUSD;
    }

    function toWEI(uint256 usdAmount)
        internal
        view
        returns (uint256)
    {
        uint ethPrice = getPrice();
        uint amount = usdAmount * 1e18 / ethPrice;
        return amount;
    }

    function findPercentageRounded(uint256 _balance, uint256 percentage) internal pure returns (uint256) {
        uint amountToRemove = _balance % 100;
        uint roundedAmount = _balance - amountToRemove;
        return ((roundedAmount * percentage ) /  100 );
    }
}