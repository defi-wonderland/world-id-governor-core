// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorDemocratic} from 'contracts/GovernorDemocratic.sol';
import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {IGoatsDAO} from 'interfaces/example/IGoatsDAO.sol';
import {Ownable} from 'open-zeppelin/access/Ownable.sol';
import {Governor} from 'open-zeppelin/governance/Governor.sol';
import {GovernorCountingSimple} from 'open-zeppelin/governance/extensions/GovernorCountingSimple.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';
import {Time} from 'open-zeppelin/utils/types/Time.sol';

/**
 * @title GoatsDAO
 * @notice Implementation of the GovernorDemocratic contract, with 1 vote per voter that is verified on WorldID. It aims
 * to be a simple DAO for donate WLD to the Goat guy.
 * @dev For this specific case, only the owner can propose.
 */
contract GoatsDAO is Ownable, GovernorCountingSimple, GovernorDemocratic, IGoatsDAO {
  /**
   * @inheritdoc IGoatsDAO
   */
  uint256 public quorumThreshold;

  /**
   * @inheritdoc IGoatsDAO
   */
  mapping(uint256 proposalId => uint256 quorumThreshold) public proposalsQuorumThreshold;

  /**
   * @notice The constructor for the GoatsDAO contract
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
    Governor('DemocraticGovernor')
    GovernorSettings(_initialVotingDelay, _initialVotingPeriod, _initialProposalThreshold)
    GovernorWorldID(_groupID, _worldIdRouter, _appId, _rootExpirationThreshold)
  {
    quorumThreshold = _quorumThreshold;
  }

  /**
   * @inheritdoc IGoatsDAO
   */
  function setQuorum(uint256 _newQuorumThreshold) external onlyGovernance {
    uint256 _oldQuorumThreshold = quorumThreshold;
    quorumThreshold = _newQuorumThreshold;
    emit QuorumSet(_oldQuorumThreshold, _newQuorumThreshold);
  }

  /**
   * @inheritdoc Governor
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
   * @inheritdoc Governor
   */
  function quorum(uint256) public view override returns (uint256 _quorumThreshold) {
    _quorumThreshold = quorumThreshold;
  }

  /**
   * @notice Clock used for flagging checkpoints
   * @return _clock The block number
   * @dev Follows the Open Zeppelin implementation when the token does not implement EIP-6372,
   *  but using timestamp instead
   */
  function clock() public view override returns (uint48 _clock) {
    _clock = Time.timestamp();
  }

  /**
   * @inheritdoc Governor
   */
  function votingDelay() public view virtual override(Governor, GovernorSettings) returns (uint256 _votingDelay) {
    _votingDelay = super.votingDelay();
  }

  /**
   * @inheritdoc Governor
   */
  function votingPeriod() public view virtual override(Governor, GovernorSettings) returns (uint256 _votingPeriod) {
    _votingPeriod = super.votingPeriod();
  }

  /**
   * @inheritdoc Governor
   */
  function proposalThreshold()
    public
    view
    virtual
    override(Governor, GovernorSettings)
    returns (uint256 _proposalThreshold)
  {
    _proposalThreshold = super.proposalThreshold();
  }

  /**
   * @notice Description of the clock mode
   * @return _mode The description of the clock mode
   * @dev Follows the Open Zeppelin implementation when the token does not implement EIP-6372,
   *  but using timestamp instead
   */
  // solhint-disable-next-line func-name-mixedcase
  function CLOCK_MODE() public pure override returns (string memory _mode) {
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
  ) internal override(Governor, GovernorWorldID) returns (uint256 _votingWeight) {
    _votingWeight = super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  /**
   * @inheritdoc GovernorWorldID
   */
  function _propose(
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    string memory _description,
    address _proposer
  ) internal virtual override(Governor, GovernorWorldID) returns (uint256 _proposalId) {
    _proposalId = super._propose(_targets, _values, _calldatas, _description, _proposer);
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
