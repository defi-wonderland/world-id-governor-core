// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IGovernorDemocratic} from 'interfaces/IGovernorDemocratic.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

/**
 * @title GovernorDemocratic
 * @notice Governor contract that assigns 1 as voting power per human, enabling a democracy
 */
abstract contract GovernorDemocratic is GovernorWorldID, IGovernorDemocratic {
  /**
   * @inheritdoc IGovernorDemocratic
   */
  uint256 public constant ONE_VOTE = 1;

  /**
   * @notice The constructor for the GovernorDemocratic contract
   * @param _groupID The WorldID group ID, 1 for orb verification level
   * @param _worldIdRouter The WorldID router instance to obtain the WorldID contract address
   * @param _appId The World ID app ID
   * @param _governorName The governor name
   * @param _initialVotingDelay The initial voting delay for the proposals
   * @param _initialVotingPeriod The initial voting period for the proposals
   * @param _initialProposalThreshold The initial proposal threshold for the proposals
   * @param _rootExpirationThreshold The root expiration threshold
   */
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    string memory _governorName,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    uint256 _rootExpirationThreshold
  )
    GovernorWorldID(
      _groupID,
      _worldIdRouter,
      _appId,
      _governorName,
      _initialVotingDelay,
      _initialVotingPeriod,
      _initialProposalThreshold,
      _rootExpirationThreshold
    )
  {}

  /**
   * @notice Returns 1 as the voting weight for the voter
   * @return _votingWeight 1 as voting weight
   */
  function _getVotes(address, uint256, bytes memory) internal view virtual override returns (uint256 _votingWeight) {
    _votingWeight = ONE_VOTE;
  }
}
