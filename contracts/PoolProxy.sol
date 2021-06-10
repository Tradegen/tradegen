pragma solidity >=0.5.0;

import './libraries/SafeMath.sol';

import './AddressResolver.sol';

contract PoolProxy is AddressResolver {

    constructor() public {
        _setPoolProxyAddress(address(this));
    }
}