// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorDemocratic} from 'contracts/GovernorDemocratic.sol';
import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IDemocraticGovernance} from 'interfaces/IDemocraticGovernance.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Ownable} from 'open-zeppelin/access/Ownable.sol';
import {Governor, IERC6372, IGovernor} from 'open-zeppelin/governance/Governor.sol';

import {GovernorCountingSimple} from 'open-zeppelin/governance/extensions/GovernorCountingSimple.sol';
import {GovernorPreventLateQuorum} from 'open-zeppelin/governance/extensions/GovernorPreventLateQuorum.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';
import {Time} from 'open-zeppelin/utils/types/Time.sol';

/**
 * @title DemocraticGovernance
 * @notice Implementation of the DemocraticGovernance contract, with 1 vote per voter that is verified on WorldID.
 * @dev For this specific case, only the owner can propose.
 */
contract DemocraticGovernance is
  Ownable,
  GovernorCountingSimple,
  GovernorPreventLateQuorum,
  GovernorWorldID,
  GovernorDemocratic,
  IDemocraticGovernance
{
  /**
   * @inheritdoc IDemocraticGovernance
   */
  uint256 public quorumThreshold;

  /**
   * @inheritdoc IDemocraticGovernance
   */
  mapping(uint256 proposalId => uint256 quorumThreshold) public proposalsQuorumThreshold;

  /**
   * @notice The constructor for the DemocraticGovernance contract
   * @param _groupID The WorldID group ID, 1 for orb verification level
   * @param _worldIdRouter The WorldID router instance to obtain the WorldID contract address
   * @param _appId The World ID app ID
   * @param _quorumThreshold The quorum threshold for the proposals
   * @param _initialVotingDelay The initial voting delay for the proposals
   * @param _initialVotingPeriod The initial voting period for the proposals
   * @param _initialProposalThreshold The initial proposal threshold for the proposals
   * @param _rootExpirationThreshold The root expiration threshold
   */
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    uint256 _quorumThreshold,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    uint256 _rootExpirationThreshold
  )
    Ownable(msg.sender)
    GovernorPreventLateQuorum(1)
    GovernorWorldID(
      _groupID,
      _worldIdRouter,
      _appId,
      'DemocraticGovernor',
      _initialVotingDelay,
      _initialVotingPeriod,
      _initialProposalThreshold,
      _rootExpirationThreshold
    )
  {
    quorumThreshold = _quorumThreshold;
  }

  function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
    return super.proposalThreshold();
  }

  /**
   * @inheritdoc IGovernor
   */
  function propose(
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    string memory _description
  ) public virtual override onlyOwner returns (uint256 _proposalId) {
    _proposalId = super.propose(_targets, _values, _calldatas, _description);
    proposalsQuorumThreshold[_proposalId] = quorumThreshold;
  }

  /**
   * @inheritdoc IDemocraticGovernance
   */
  function setQuorum(uint256 _newQuorumThreshold) public onlyGovernance {
    uint256 _oldQuorumThreshold = quorumThreshold;
    quorumThreshold = _newQuorumThreshold;
    emit QuorumSet(_oldQuorumThreshold, _newQuorumThreshold);
  }

  /**
   * @inheritdoc IGovernor
   */
  function quorum(uint256) public view override returns (uint256 _quorumThreshold) {
    _quorumThreshold = quorumThreshold;
  }

  /**
   * @inheritdoc IDemocraticGovernance
   */
  function clock() public view override(Governor, IDemocraticGovernance) returns (uint48 _clock) {
    _clock = Time.timestamp();
  }

  /**
   * @inheritdoc IDemocraticGovernance
   */
  // solhint-disable-next-line func-name-mixedcase
  function CLOCK_MODE() public pure override(Governor, IDemocraticGovernance) returns (string memory _mode) {
    _mode = 'mode=blocktimestamp&from=default';
  }

  /**
   * @inheritdoc GovernorWorldID
   */
  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) internal override(Governor, GovernorWorldID) returns (uint256) {
    super._castVote(_proposalId, _account, _support, _reason);
  }

  /**
   * @inheritdoc GovernorWorldID
   */
  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) internal override(GovernorPreventLateQuorum, Governor, GovernorWorldID) returns (uint256 _votingWeight) {
    _votingWeight = super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  /**
   * @inheritdoc GovernorCountingSimple
   */
  function _quorumReached(uint256 proposalId)
    internal
    view
    virtual
    override(Governor, GovernorCountingSimple)
    returns (bool _reached)
  {
    (, uint256 _forVotes, uint256 _abstainVotes) = proposalVotes(proposalId);
    uint256 _quorum = proposalsQuorumThreshold[proposalId];
    _reached = _quorum <= (_forVotes + _abstainVotes);
  }

  function proposalDeadline(uint256 _proposalId)
    public
    view
    override(Governor, GovernorPreventLateQuorum)
    returns (uint256 _deadline)
  {
    _deadline = super.proposalDeadline(_proposalId);
  }
}
