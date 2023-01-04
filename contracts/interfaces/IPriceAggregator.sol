// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IPriceAggregator {
    /**
    * @notice Returns the current USD price of the given asset.
    */
    function getUSDPrice(address asset) external view returns (uint);
}