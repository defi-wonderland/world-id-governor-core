// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {Governor} from 'open-zeppelin/governance/Governor.sol';

/**
 * @dev Abstraction on top of Governor, it disables some functions that are not compatible
 * and checks if the voter is a real human before proceeding with the vote.
 */
abstract contract GovernorWorldID is IGovernorWorldID, Governor {
  using ByteHasher for bytes;

  /// @dev The World ID instance that will be used for verifying proofs
  IWorldID internal immutable _WORLD_ID;

  /// @dev The contract's external nullifier hash
  uint256 internal immutable _EXTERNAL_NULLIFIER;

  /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
  mapping(uint256 => bool) internal _nullifierHashes;

  /// @dev The latest root verifier for each voter
  mapping(address => uint256) internal _latestRootPerVoter;

  /// @param _groupID The WorldID group ID, 1 for orb verification level
  /// @param _worldIdRouter The WorldID router instance to obtain the WorldID contract address
  /// @param _appId The World ID app ID
  /// @param _actionId The World ID action ID
  /// @param _name The governor name
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    string memory _actionId,
    string memory _name
  ) Governor(_name) {
    _WORLD_ID = IWorldID(_worldIdRouter.routeFor(_groupID));
    _EXTERNAL_NULLIFIER = abi.encodePacked(abi.encodePacked(_appId).hashToField(), _actionId).hashToField();
  }

  function _isHuman(address _voter, uint256 _proposalId, bytes memory _proofData) internal virtual {
    if (_proofData.length == 0) revert GovernorWorldID_NoProofData();

    // Decode the parameters
    (uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) =
      abi.decode(_proofData, (uint256, uint256, uint256[8]));

    // Check that the nullifier hash has not been used before
    if (_nullifierHashes[_nullifierHash]) revert GovernorWorldID_InvalidNullifier();

    // Get the current root
    uint256 _currentRoot = _WORLD_ID.latestRoot();

    // If the user has already verified himself on the latest root, skip the verification
    if (_latestRootPerVoter[_voter] == _currentRoot) return;

    if (_root != _currentRoot) revert GovernorWorldID_OutdatedRoot();

    // Verify the provided proof
    uint256 _signal = abi.encodePacked(_proposalId, _voter).hashToField();
    _WORLD_ID.verifyProof(_root, _signal, _nullifierHash, _EXTERNAL_NULLIFIER, _proof);

    // Save the verified nullifier hash
    _nullifierHashes[_nullifierHash] = true;

    // Save the latest root for the user
    _latestRootPerVoter[_voter] = _currentRoot;
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
    // Check if the voter is a registered human
    _isHuman(_account, _proposalId, _params);

    return super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  /**
   * @notice This function is disabled because is not compatible with the new implementations. It will make revert the functions that implement it as: `castVote`, `castVoteWithReason`, `castVoteBySig`.
   */
  function _castVote(uint256, address, uint8, string memory) internal virtual override returns (uint256) {
    revert GovernorWorldID_NotSupportedFunction();
  }
}
