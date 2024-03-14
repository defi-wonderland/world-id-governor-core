// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorDemocratic} from 'contracts/GovernorDemocratic.sol';
import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
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
contract DemocraticGovernance is Ownable, GovernorCountingSimple, GovernorDemocratic {
  /**
   * @notice The quorum threshold for the democratic governance
   */
  uint256 public quorumThreshold;

  /**
   * @notice The mapping of the proposal ID to the quorum threshold
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
    proposalsQuorumThreshold[_proposalId] = quorumThreshold;
    return super.propose(_targets, _values, _calldatas, _description);
  }

  /**
   * @notice Set the quorum for the democratic governance
   * @dev Only the governance can set the quorum
   * @param _quorumThreshold The new quorum
   */
  function setQuorum(uint256 _quorumThreshold) public onlyOwner {
    quorumThreshold = _quorumThreshold;
  }

  /**
   * @notice Minimum number of cast voted required for a proposal to be successful.
   * @return _quorumThreshold The current minimum number of cast votes required for a proposal to be successful
   */
  function quorum(uint256) public view override(Governor, IGovernor) returns (uint256 _quorumThreshold) {
    _quorumThreshold = quorumThreshold;
  }

  /**
   * @notice Clock used for flagging checkpoints
   * @return _clock The block number
   * @dev Follows the Open Zeppelin implementation when the token does not implement EIP-6372, but using timestamp instead
   */
  function clock() public view override(Governor, IERC6372) returns (uint48 _clock) {
    _clock = Time.timestamp();
  }

  /**
   * @notice Description of the clock mode
   * @return _mode The description of the clock mode
   * @dev Follows the Open Zeppelin implementation when the token does not implement EIP-6372, but using timestamp instead
   */
  // solhint-disable-next-line func-name-mixedcase
  function CLOCK_MODE() public pure override(Governor, IERC6372) returns (string memory _mode) {
    _mode = 'mode=timestamp&from=default';
  }

  /**
   * @notice The delay before voting starts for a proposal
   * @return _delay The delay before voting starts for a proposal
   */
  function votingDelay() public pure override(Governor, IGovernor) returns (uint256 _delay) {
    _delay = 1 days;
  }

  /**
   * @notice The duration of the voting period for a proposal
   * @return _duration The duration of the voting period for a proposal
   */
  function votingPeriod() public pure override(Governor, IGovernor) returns (uint256 _duration) {
    _duration = 1 weeks;
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
    _votingWeight = super._castVote(_proposalId, _account, _support, _reason);
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
    _votingWeight = super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  /**
   * @dev See {Governor-_quorumReached}.
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
  ) internal view virtual override(Governor, GovernorDemocratic) returns (uint256 _votingWeight) {
    _votingWeight = super._getVotes(_account, _timepoint, _params);
  }
}
