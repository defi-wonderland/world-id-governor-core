// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library ByteHasher {
  /**
   * @dev Creates a keccak256 hash of a bytestring. `>> 8` makes sure that the result is included in our field.
   * @param _value The bytestring to hash
   * @return _hash The hash of the specified value
   */
  function hashToField(bytes memory _value) internal pure returns (uint256 _hash) {
    _hash = uint256(keccak256(abi.encodePacked(_value))) >> 8;
  }
}
