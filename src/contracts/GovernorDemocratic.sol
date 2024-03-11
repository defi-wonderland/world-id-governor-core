// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Governor, IERC6372} from 'open-zeppelin/governance/Governor.sol';
import {GovernorVotes, IVotes} from 'open-zeppelin/governance/extensions/GovernorVotes.sol';

abstract contract GovernorDemocratic is GovernorWorldID, GovernorVotes {
  uint256 internal constant _ONE_VOTE = 1;

  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    string memory _actionId,
    string memory _name,
    IVotes _token
  ) GovernorWorldID(_groupID, _worldIdRouter, _appId, _actionId, _name) GovernorVotes(_token) {}

  /**
   * @notice Returns 1 as the voting weight for the voter
   * @return _votingWeight address The voter address
   */
  function _getVotes(
    address,
    uint256,
    bytes memory
  ) internal view virtual override(Governor, GovernorVotes) returns (uint256 _votingWeight) {
    return _ONE_VOTE;
  }

  // solhint-disable-next-line
  function CLOCK_MODE() public view virtual override(Governor, GovernorVotes, IERC6372) returns (string memory) {
    return super.CLOCK_MODE();
  }

  function clock() public view virtual override(Governor, GovernorVotes, IERC6372) returns (uint48) {
    return super.clock();
  }

  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) internal virtual override(Governor, GovernorWorldID) returns (uint256) {
    return super._castVote(_proposalId, _account, _support, _reason);
  }

  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) internal virtual override(Governor, GovernorWorldID) returns (uint256) {
    return super._castVote(_proposalId, _account, _support, _reason, _params);
  }
}
