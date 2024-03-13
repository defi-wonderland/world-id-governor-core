// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorDemocratic} from 'contracts/GovernorDemocratic.sol';
import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Governor, IERC6372, IGovernor} from 'open-zeppelin/governance/Governor.sol';
import {GovernorCountingSimple} from 'open-zeppelin/governance/extensions/GovernorCountingSimple.sol';
import {GovernorVotes, IVotes} from 'open-zeppelin/governance/extensions/GovernorVotes.sol';
import {GovernorVotesQuorumFraction} from 'open-zeppelin/governance/extensions/GovernorVotesQuorumFraction.sol';
import {Ownable} from 'open-zeppelin/access/Ownable.sol';

/**
 * @title DemocraticGovernance
 * @notice Implementation of the DemocraticGovernance contract, with 1 vote per voter that is verified on WorldID.
 * @dev For this specific case only the owner can propose.
 */
contract DemocraticGovernance is
  Ownable,
  GovernorVotes,
  GovernorCountingSimple,
  GovernorVotesQuorumFraction,
  GovernorDemocratic
{
  /**
   * @notice The constructor for the DemocraticGovernance contract
   * @param _groupID The WorldID group ID, 1 for orb verification level
   * @param _worldIdRouter The WorldID router instance to obtain the WorldID contract address
   * @param _appId The World ID app ID
   * @param _actionId The World ID action ID
   * @param _token The token instance to be used for voting
   */
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    string memory _actionId,
    IVotes _token
  )
    Ownable(msg.sender)
    GovernorVotes(_token)
    GovernorVotesQuorumFraction(4)
    GovernorDemocratic(_groupID, _worldIdRouter, _appId, _actionId, 'DemocraticGovernor')
  {}

  /**
   * @notice Propose a new proposal for the democratic governance
   * @dev Only the owner can propose
   * @param _targets The addresses of the contracts to be called
   * @param _values The values to be sent to the contracts
   * @param _calldatas The calldatas to be sent to the contracts
   * @param _description The description of the proposal
   * @return _proposalId The ID of the proposal
   */
  function propose(
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    string memory _description
  ) public virtual override(Governor, IGovernor) onlyOwner returns (uint256 _proposalId) {
    return super.propose(_targets, _values, _calldatas, _description);
  }

  /**
   * @notice Minimum number of cast voted required for a proposal to be successful.
   * @param _blockNumber The block number to check the snapshot used for counting vote
   * @return _quorum The minimum number of cast votes required for a proposal to be successful
   */
  function quorum(uint256 _blockNumber)
    public
    view
    override(Governor, IGovernor, GovernorVotesQuorumFraction)
    returns (uint256 _quorum)
  {
    return super.quorum(_blockNumber);
  }

  /**
   * @notice Description of the clock mode
   * @return _mode The description of the clock mode
   */
  // solhint-disable-next-line func-name-mixedcase
  function CLOCK_MODE() public view override(Governor, GovernorVotes, IERC6372) returns (string memory _mode) {
    return super.CLOCK_MODE();
  }

  /**
   * @notice Clock used for flagging checkpoints
   * @return _clock The clock used for flagging checkpoints
   */
  function clock() public view override(Governor, GovernorVotes, IERC6372) returns (uint48 _clock) {
    return super.clock();
  }

  /**
   * @notice The delay before voting starts for a proposal
   * @return _delay The delay before voting starts for a proposal
   */
  function votingDelay() public pure override(Governor, IGovernor) returns (uint256 _delay) {
    return 7200; // 1 day
  }

  /**
   * @notice The duration of the voting period for a proposal
   * @return _duration The duration of the voting period for a proposal
   */
  function votingPeriod() public pure override(Governor, IGovernor) returns (uint256 _duration) {
    return 50_400; // 1 week
  }

  /**
   * @notice Cast a vote for a proposal without extra params
   * @param _proposalId The ID of the proposal
   * @param _account The account that is casting the vote
   * @param _support The support value of the vote
   * @param _reason The reason for the vote
   * @return _votingWeight The voting weight of the voter
   */
  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) internal override(Governor, GovernorWorldID) returns (uint256 _votingWeight) {
    return super._castVote(_proposalId, _account, _support, _reason);
  }

  /**
   * @notice Cast a vote for a proposal with extra params
   * @param _proposalId The ID of the proposal
   * @param _account The account that is casting the vote
   * @param _support The support value of the vote
   * @param _reason The reason for the vote
   * @param _params The extra params for the vote
   * @return _votingWeight The voting weight of the voter
   */
  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) internal override(Governor, GovernorWorldID) returns (uint256 _votingWeight) {
    return super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  /**
   * @notice Get the voting weight of a voter
   * @param _account The account to get the voting weight
   * @param _timepoint The timepoint to get the voting weight
   * @param _params The extra params for the vote
   * @return _votingWeight The voting weight of the voter
   */
  function _getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) internal view virtual override(Governor, GovernorVotes, GovernorDemocratic) returns (uint256 _votingWeight) {
    return super._getVotes(_account, _timepoint, _params);
  }
}
