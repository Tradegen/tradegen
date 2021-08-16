// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface ISettings {
    /**
    * @dev Given the name of a parameter, returns the value of the parameter
    * @param parameter The name of the parameter to get value for
    * @return uint The value of the given parameter
    */
    function getParameterValue(string memory parameter) external view returns (uint);
}