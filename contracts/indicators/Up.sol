pragma solidity >=0.5.0;

import '../AddressResolver.sol';

import '../interfaces/IIndicator.sol';

contract Up is IIndicator, AddressResolver {

    constructor() public onlyImports(msg.sender) {}

    function getName() public pure override returns (string memory) {
        return "Up";
    }

    function update(uint latestPrice) public override {}   

    function getValue() public pure override returns (uint[] memory) {
        uint[] memory temp = new uint[](1);
        temp[0] = 1;
        return temp;
    }

    function getHistory() public pure override returns (uint[] memory) {
        return new uint[](0);
    }
}