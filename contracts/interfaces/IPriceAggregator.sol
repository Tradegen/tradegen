// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IPriceAggregator {
    function getUSDPrice(address asset) external view returns (uint);
}