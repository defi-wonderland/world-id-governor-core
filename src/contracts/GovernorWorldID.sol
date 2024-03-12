// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {Governor} from 'open-zeppelin/governance/Governor.sol';

/**
 * @title GovernorWorldID
 * @notice Governor contract that checks if the voter is a real human before proceeding with the vote.
 */
abstract contract GovernorWorldID is Governor, IGovernorWorldID {
  using ByteHasher for bytes;

  /// @dev The World ID instance that will be used for verifying proofs
  IWorldID public immutable WORLD_ID;

  /// @dev The contract's external nullifier hash. It's composed by the `appId` and `actionId` and is used to verify the proofs.
  uint256 public immutable EXTERNAL_NULLIFIER;

  /// @dev The latest root verifier for each voter
  mapping(address => uint256) public latestRootPerVoter;

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
    WORLD_ID = IWorldID(_worldIdRouter.routeFor(_groupID));
    EXTERNAL_NULLIFIER = abi.encodePacked(abi.encodePacked(_appId).hashToField(), _actionId).hashToField();
  }

  /**
   * @notice Check if the voter is a real human
   * @param _account The account of the voter address
   * @param _proposalId The proposal id
   * @param _proofData The proof data
   */
  function _isHuman(address _account, uint256 _proposalId, bytes memory _proofData) internal virtual {
    // Get the current root
    uint256 _currentRoot = WORLD_ID.latestRoot();

    // If the user has already verified himself on the latest root, skip the verification
    if (latestRootPerVoter[_account] == _currentRoot) return;

    if (_proofData.length == 0) revert GovernorWorldID_NoProofData();

    // Decode the parameters
    (uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) =
      abi.decode(_proofData, (uint256, uint256, uint256[8]));

    if (_root != _currentRoot) revert GovernorWorldID_OutdatedRoot();

    // Verify the provided proof
    uint256 _signal = abi.encodePacked(_proposalId, _account).hashToField();
    WORLD_ID.verifyProof(_root, _signal, _nullifierHash, EXTERNAL_NULLIFIER, _proof);

    // Save the latest root for the user
    latestRootPerVoter[_account] = _currentRoot;
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
