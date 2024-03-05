// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MessageHashUtils} from 'open-zeppelin/utils/cryptography/MessageHashUtils.sol';

contract GovernorSigUtils {
  using MessageHashUtils for bytes32;

  bytes32 public constant TYPE_HASH =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public immutable DOMAIN_SEPARATOR;
  uint256 public nonce; // NOTE: hardcoding the nonce to 0

  constructor(address _governorAddress) {
    bytes32 _hashedName = keccak256(bytes('Governor'));
    bytes32 _hashedVersion = keccak256(bytes('1'));
    DOMAIN_SEPARATOR = keccak256(abi.encode(TYPE_HASH, _hashedName, _hashedVersion, block.chainid, _governorAddress));
  }

  function getHash(uint256 _proposalId, uint8 _support, address _voter) public view returns (bytes32 _hash) {
    bytes32 _ballotTypehash = keccak256('Ballot(uint256 proposalId,uint8 support,address voter,uint256 nonce)');
    _hash = _hashTypedDataV4(keccak256(abi.encode(_ballotTypehash, _proposalId, _support, _voter, nonce)));
  }

  function getHash(
    uint256 _proposalId,
    uint8 _support,
    address _voter,
    string memory _reason,
    bytes memory _params
  ) public view returns (bytes32 _hash) {
    bytes32 _extendedBallotTypehash = keccak256(
      'ExtendedBallot(uint256 proposalId,uint8 support,address voter,uint256 nonce,string reason,bytes params)'
    );
    _hash = _hashTypedDataV4(
      keccak256(
        abi.encode(
          _extendedBallotTypehash, _proposalId, _support, _voter, nonce, keccak256(bytes(_reason)), keccak256(_params)
        )
      )
    );
  }

  function _hashTypedDataV4(bytes32 _structHash) internal view virtual returns (bytes32) {
    return MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, _structHash);
  }
}
