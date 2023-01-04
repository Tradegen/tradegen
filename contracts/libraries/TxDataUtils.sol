// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

// OpenZeppelin.
import "../openzeppelin-solidity/SafeMath.sol";

// Libraries.
import "./BytesLib.sol";

contract TxDataUtils {
  using BytesLib for bytes;
  using SafeMath for uint256;

  /**
  * @notice Returns the method name from the given bytes.
  * @dev Assumes that the given bytes represent a function signature.
  */
  function getMethod(bytes calldata data) public pure returns (bytes4) {
    return read4left(data, 0);
  }

  /**
  * @notice Returns the function parameters from the given bytes.
  * @dev Assumes that the given bytes represent a function signature.
  */
  function getParams(bytes calldata data) external pure returns (bytes memory) {
    return data.slice(4, data.length - 4);
  }

  /**
  * @notice Returns the function parameter at a given index from the bytes data.
  * @dev Assumes that the given bytes represent a function signature.
  * @dev Throws an error if the index is out of bounds.
  */
  function getInput(bytes calldata data, uint8 inputNum) public pure returns (bytes32) {
    return read32(data, 32 * inputNum + 4, 32);
  }

  /**
  * @notice Returns the bytes data at a given index with an offset applied.
  */
  function getBytes(
    bytes calldata data,
    uint8 inputNum,
    uint256 offset
  ) public pure returns (bytes memory) {
    require(offset < 20, "TxDataUtils: Invalid offset."); // Offset is in byte32 slots, not bytes.

    offset = offset * 32; // Convert offset to bytes.
    uint256 bytesLenPos = uint256(read32(data, 32 * inputNum + 4 + offset, 32));
    uint256 bytesLen = uint256(read32(data, bytesLenPos + 4 + offset, 32));

    return data.slice(bytesLenPos + 4 + offset + 32, bytesLen);
  }

  /**
  * @notice Returns the data at the last index of an array.
  * @dev Assumes that the given bytes represent an array.
  */
  function getArrayLast(bytes calldata data, uint8 inputNum) public pure returns (bytes32) {
    bytes32 arrayPos = read32(data, 32 * inputNum + 4, 32);
    bytes32 arrayLen = read32(data, uint256(arrayPos) + 4, 32);

    require(arrayLen > 0, "TxDataUtils: Input is not array.");

    return read32(data, uint256(arrayPos) + 4 + (uint256(arrayLen) * 32), 32);
  }

  /**
  * @notice Returns the data at the length of an array.
  * @dev Assumes that the given bytes represent an array.
  */
  function getArrayLength(bytes calldata data, uint8 inputNum) external pure returns (uint256) {
    bytes32 arrayPos = read32(data, 32 * inputNum + 4, 32);

    return uint256(read32(data, uint256(arrayPos) + 4, 32));
  }

  /**
  * @notice Returns the data at the given index of an array.
  * @dev Assumes that the given bytes represent an array.
  * @dev Throws an error if the index is out of bounds.
  */
  function getArrayIndex(
    bytes calldata data,
    uint8 inputNum,
    uint8 arrayIndex
  ) public pure returns (bytes32) {
    bytes32 arrayPos = read32(data, 32 * inputNum + 4, 32);
    bytes32 arrayLen = read32(data, uint256(arrayPos) + 4, 32);

    require(arrayLen > 0, "TxDataUtils: Input is not array.");
    require(uint256(arrayLen) > arrayIndex, "TxDataUtils: Invalid array position.");

    return read32(data, uint256(arrayPos) + 4 + ((1 + uint256(arrayIndex)) * 32), 32);
  }

  /**
  * @notice Reads the first 4 bytes from the left of the given data with an offset applied.
  */
  function read4left(bytes memory data, uint256 offset) public pure returns (bytes4 o) {
    require(data.length >= offset + 4, "TxDataUtils: Reading bytes out of bounds.");

    assembly {
      o := mload(add(data, add(32, offset)))
    }
  }

  /**
  * @notice Reads 'length' bytes from the given data with an offset applied.
  * @dev Throws an error if 'offset + length' is out of bounds.
  */
  function read32(
    bytes memory data,
    uint256 offset,
    uint256 length
  ) public pure returns (bytes32 o) {
    require(data.length >= offset + length, "TxDataUtils: Reading bytes out of bounds.");

    assembly {
      o := mload(add(data, add(32, offset)))
      let lb := sub(32, length)
      if lb {
        o := div(o, exp(2, mul(lb, 8)))
      }
    }
  }

  /**
  * @notice Converts the given bytes to an address.
  */
  function convert32toAddress(bytes32 data) public pure returns (address) {
    return address(uint160(uint256(data)));
  }

  /**
  * @notice Converts the given bytes to a uint.
  */
  function sliceUint(bytes memory data, uint256 start) internal pure returns (uint256) {
    require(data.length >= start + 32, "TxDataUtils: Slicing out of range.");

    uint256 x;
    assembly {
      x := mload(add(data, add(0x20, start)))
    }
    return x;
  }
}