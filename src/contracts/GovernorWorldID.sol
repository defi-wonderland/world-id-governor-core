// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {Governor} from 'open-zeppelin/governance/Governor.sol';

/**
 * @dev Abstraction on top of Governor, it disables some functions that are not compatible
 * and checks if the voter is a real human before proceeding with the vote.
 */
abstract contract GovernorWorldID is IGovernorWorldID, Governor {
  using ByteHasher for bytes;

  /// @dev The World ID group ID
  uint256 internal immutable _GROUP_ID;

  /// @dev The World ID instance that will be used for verifying proofs
  IWorldID internal immutable _WORLD_ID;

  /// @dev The contract's external nullifier hash
  uint256 internal immutable _EXTERNAL_NULLIFIER;

  /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
  mapping(uint256 => bool) internal _nullifierHashes;

  /// @param _groupID The WorldID group ID, 1 for orb verification level
  /// @param _worldId The WorldID instance that will verify the proofs
  /// @param _appId The World ID app ID
  /// @param _actionId The World ID action ID
  /// @param _name The governor name
  constructor(
    uint256 _groupID,
    IWorldID _worldId,
    string memory _appId,
    string memory _actionId,
    string memory _name
  ) Governor(_name) {
    _GROUP_ID = _groupID;
    _WORLD_ID = _worldId;
    _EXTERNAL_NULLIFIER = abi.encodePacked(abi.encodePacked(_appId).hashToField(), _actionId).hashToField();
  }

  /**
   * @notice Cast a vote for a proposal
   * @dev It checks if the voter is a real human before proceeding with the vote
   * @param _proposalId The proposal id
   * @param _account The account that is casting the vote
   * @param _support The support value, 0 for against and 1 for in favor
   * @param _reason The reason for the vote
   * @param _params The parameters for the vote
   * @return _votingWeight The voting weight of the voter
   */
  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) internal virtual override returns (uint256 _votingWeight) {
    // Decode the parameters
    (uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) =
      abi.decode(_params, (uint256, uint256, uint256[8]));

    // Check that the nullifier hash has not been used before
    if (_nullifierHashes[_nullifierHash]) revert GovernorWorldID_InvalidNullifier();

    // Verify the provided proof
    uint256 _signal = abi.encodePacked(_proposalId, _account).hashToField();
    _WORLD_ID.verifyProof(_root, _GROUP_ID, _signal, _nullifierHash, _EXTERNAL_NULLIFIER, _proof);

    // Save the verified nullifier hash
    _nullifierHashes[_nullifierHash] = true;

    return super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  /**
   * @notice This function is disabled because is not compatible with the new implementations. It will make revert the functions that implement it as: `castVote`, `castVoteWithReason`, `castVoteBySig`.
   */
  function _castVote(uint256, address, uint8, string memory) internal virtual override returns (uint256) {
    revert GovernorWorldID_NotSupportedFunction();
  }
}
