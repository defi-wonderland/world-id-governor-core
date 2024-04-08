// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Governor, IERC6372, IGovernor} from 'open-zeppelin/governance/Governor.sol';
import {GovernorCountingSimple} from 'open-zeppelin/governance/extensions/GovernorCountingSimple.sol';
import {GovernorVotes, IVotes} from 'open-zeppelin/governance/extensions/GovernorVotes.sol';
import {GovernorVotesQuorumFraction} from 'open-zeppelin/governance/extensions/GovernorVotesQuorumFraction.sol';

contract GovernorWorldIdForTest is GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, GovernorWorldID {
  struct ConstructorArgs {
    uint256 groupID;
    IWorldIDRouter worldIdRouter;
    string appId;
    IVotes token;
    uint48 initialVotingDelay;
    uint32 initialVotingPeriod;
    uint256 initialProposalThreshold;
    uint256 rootExpirationThreshold;
  }

  constructor(ConstructorArgs memory _args)
    GovernorWorldID(
      _args.groupID,
      _args.worldIdRouter,
      _args.appId,
      'Governor',
      _args.initialVotingDelay,
      _args.initialVotingPeriod,
      _args.initialProposalThreshold,
      _args.rootExpirationThreshold
    )
    GovernorVotes(_args.token)
    GovernorVotesQuorumFraction(4)
  {}

  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) public {
    _castVote(_proposalId, _account, _support, _reason, _params);
  }

  function forTest_setNullifierHash(uint256 _nullifierHash, bool _isUsed) public {
    nullifierHashes[_nullifierHash] = _isUsed;
  }

  function forTest_setRootExpirationThreshold(uint256 _newRootExpirationThreshold) public {
    rootExpirationThreshold = _newRootExpirationThreshold;
  }

  function forTest_setResetGracePeriod(uint256 _newResetGracePeriod) public {
    resetGracePeriod = _newResetGracePeriod;
  }

  function forTest_setVotingPeriodInternal(uint32 _newVotingPeriod) public {
    _setVotingPeriod(_newVotingPeriod);
  }

  function forTest_checkVoteValidity(
    uint8 _support,
    uint256 _proposalId,
    bytes memory _proofData
  ) public returns (uint256 _nullifierHash) {
    _nullifierHash = _checkVoteValidity(_support, _proposalId, _proofData);
  }

  function forTest_checkRootExpirationThreshold(uint256 _rootExpirationThreshold) public view {
    return _checkRootExpirationThreshold(_rootExpirationThreshold);
  }

  function quorum(uint256 blockNumber)
    public
    view
    override(Governor, IGovernor, GovernorVotesQuorumFraction)
    returns (uint256)
  {
    return super.quorum(blockNumber);
  }

  // solhint-disable-next-line
  function CLOCK_MODE() public view override(Governor, GovernorVotes, IERC6372) returns (string memory) {
    return super.CLOCK_MODE();
  }

  function clock() public view override(Governor, GovernorVotes, IERC6372) returns (uint48) {
    return super.clock();
  }

  function votingDelay() public view virtual override(Governor, GovernorWorldID) returns (uint256) {
    return super.votingDelay();
  }

  function votingPeriod() public view virtual override(Governor, GovernorWorldID) returns (uint256) {
    return super.votingPeriod();
  }

  function proposalThreshold() public view virtual override(Governor, GovernorWorldID) returns (uint256) {
    return super.proposalThreshold();
  }

  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) internal override(Governor, GovernorWorldID) returns (uint256) {
    return super._castVote(_proposalId, _account, _support, _reason);
  }

  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) internal override(Governor, GovernorWorldID) returns (uint256) {
    return super._castVote(_proposalId, _account, _support, _reason, _params);
  }
}
