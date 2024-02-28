// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Governor} from 'open-zeppelin/governance/Governor.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';

abstract contract GovernorWorldID is IGovernorWorldID, Governor {
  using ByteHasher for bytes;

  /// @dev The World ID group ID (always 1)
  uint256 internal constant _GROUP_ID = 1;

  /// @dev The World ID instance that will be used for verifying proofs
  IWorldID internal immutable _WORLD_ID;

  /// @dev The contract's external nullifier hash
  uint256 internal immutable _EXTERNAL_NULLIFIER;

  /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
  mapping(uint256 => bool) internal _nullifierHashes;

  /// @param _worldId The WorldID instance that will verify the proofs
  /// @param _appId The World ID app ID
  /// @param _actionId The World ID action ID
  /// @param _name The governor name
  constructor(IWorldID _worldId, string memory _appId, string memory _actionId, string memory _name) Governor(_name) {
    _WORLD_ID = _worldId;
    _EXTERNAL_NULLIFIER = abi.encodePacked(abi.encodePacked(_appId).hashToField(), _actionId).hashToField();
  }

  function castVoteWithReasonAndParams(
    uint256 _proposalId,
    uint8 _support,
    string calldata _reason,
    bytes memory _params
  ) public override returns (uint256 _votingWeight) {
    // Decode the parameters
    (address _signal, uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) =
      abi.decode(_params, (address, uint256, uint256, uint256[8]));

    // Verify that is a human
    _isHuman(_signal, _root, _nullifierHash, _proof);

    // Continue with normal code execution
    return super.castVoteWithReasonAndParams(_proposalId, _support, _reason, _params);
  }

  function castVoteWithReasonAndParamsBySig(
    uint256 _proposalId,
    uint8 _support,
    address _voter,
    string calldata _reason,
    bytes memory _params,
    bytes memory _signature
  ) public override returns (uint256 _votingWeight) {
    // Decode the parameters
    (address _signal, uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) =
      abi.decode(_params, (address, uint256, uint256, uint256[8]));

    // Verify that is a human
    _isHuman(_signal, _root, _nullifierHash, _proof);

    // Continue with normal code execution
    return super.castVoteWithReasonAndParamsBySig(_proposalId, _support, _voter, _reason, _params, _signature);
  }

  function castVote(uint256, uint8) public pure override returns (uint256) {
    revert GovernorWorldID_NotSupportedFunction();
  }

  function castVoteWithReason(uint256, uint8, string calldata) public pure override returns (uint256) {
    revert GovernorWorldID_NotSupportedFunction();
  }

  function castVoteBySig(uint256, uint8, address, bytes memory) public pure override returns (uint256) {
    revert GovernorWorldID_NotSupportedFunction();
  }

  function _isHuman(address _signal, uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) internal {
    // Check that the nullifier hash has not been used before
    if (_nullifierHashes[_nullifierHash]) revert GovernorWorldID_InvalidNullifier();

    // Verify the provided proof
    _WORLD_ID.verifyProof(
      _root, _GROUP_ID, abi.encodePacked(_signal).hashToField(), _nullifierHash, _EXTERNAL_NULLIFIER, _proof
    );

    // Save the verified nullifier hash
    _nullifierHashes[_nullifierHash] = true;
  }

  function _castVote(uint256, address, uint8, string memory) internal pure override returns (uint256) {
    revert GovernorWorldID_NotSupportedFunction();
  }
}
