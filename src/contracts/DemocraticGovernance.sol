// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorDemocratic} from 'contracts/GovernorDemocratic.sol';
import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IDemocraticGovernance} from 'interfaces/IDemocraticGovernance.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Ownable} from 'open-zeppelin/access/Ownable.sol';
import {Governor, IERC6372, IGovernor} from 'open-zeppelin/governance/Governor.sol';
import {GovernorCountingSimple} from 'open-zeppelin/governance/extensions/GovernorCountingSimple.sol';
import {Time} from 'open-zeppelin/utils/types/Time.sol';

/**
 * @title DemocraticGovernance
 * @notice Implementation of the DemocraticGovernance contract, with 1 vote per voter that is verified on WorldID.
 * @dev For this specific case only the owner can propose.
 */
contract DemocraticGovernance is Ownable, GovernorCountingSimple, GovernorDemocratic, IDemocraticGovernance {
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
   * @param _actionId The World ID action ID
   */
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    string memory _actionId,
    uint256 _quorumThreshold
  ) Ownable(msg.sender) GovernorDemocratic(_groupID, _worldIdRouter, _appId, _actionId, 'DemocraticGovernor') {
    quorumThreshold = _quorumThreshold;
  }

  /**
   * @inheritdoc IGovernor
   */
  function propose(
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    string memory _description
  ) public virtual override(Governor, IGovernor) onlyOwner returns (uint256 _proposalId) {
    _proposalId = super.propose(_targets, _values, _calldatas, _description);
    proposalsQuorumThreshold[_proposalId] = quorumThreshold;
  }

  /**
   * @inheritdoc IDemocraticGovernance
   */
  function setQuorum(uint256 _quorumThreshold) public onlyOwner {
    quorumThreshold = _quorumThreshold;

    emit QuorumSet(_quorumThreshold);
  }

  /**
   * @inheritdoc IGovernor
   */
  function quorum(uint256) public view override(Governor, IGovernor) returns (uint256 _quorumThreshold) {
    _quorumThreshold = quorumThreshold;
  }

  /**
   * @inheritdoc IDemocraticGovernance
   */
  function clock() public view override(Governor, IERC6372, IDemocraticGovernance) returns (uint48 _clock) {
    _clock = Time.timestamp();
  }

  /**
   * @inheritdoc IDemocraticGovernance
   */
  // solhint-disable-next-line func-name-mixedcase
  function CLOCK_MODE() public pure override(Governor, IERC6372, IDemocraticGovernance) returns (string memory _mode) {
    _mode = 'mode=blocktimestamp&from=default';
  }

  /**
   * @inheritdoc IGovernor
   */
  function votingDelay() public pure override(Governor, IGovernor) returns (uint256 _delay) {
    _delay = 1 days;
  }

  /**
   * @inheritdoc IGovernor
   */
  function votingPeriod() public pure override(Governor, IGovernor) returns (uint256 _duration) {
    _duration = 1 weeks;
  }

  /**
   * @inheritdoc GovernorWorldID
   */
  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) internal override(Governor, GovernorWorldID) returns (uint256 _votingWeight) {
    _votingWeight = super._castVote(_proposalId, _account, _support, _reason);
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
  ) internal override(Governor, GovernorWorldID) returns (uint256 _votingWeight) {
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

  /**
   * @inheritdoc GovernorDemocratic
   */
  function _getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) internal view virtual override(Governor, GovernorDemocratic) returns (uint256 _votingWeight) {
    _votingWeight = super._getVotes(_account, _timepoint, _params);
  }
}
