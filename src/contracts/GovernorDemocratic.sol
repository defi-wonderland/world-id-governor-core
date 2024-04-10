// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IGovernorDemocratic} from 'interfaces/IGovernorDemocratic.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Governor} from 'open-zeppelin/governance/Governor.sol';

/**
 * @title GovernorDemocratic
 * @notice Governor contract that assigns 1 as voting power per human, enabling a democracy
 */
abstract contract GovernorDemocratic is Governor {
  // /**
  //  * @inheritdoc IGovernorDemocratic
  //  */
  uint256 public constant ONE_VOTE = 1;

  /**
   * @notice Returns 1 as the voting weight for the voter
   * @return _votingWeight 1 as voting weight
   */
  function _getVotes(address, uint256, bytes memory) internal view virtual override returns (uint256 _votingWeight) {
    _votingWeight = ONE_VOTE;
  }
}
