// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

abstract contract GovernorDemocratic is GovernorWorldID {
  /**
   * @notice The constant holding the votes for every voter (1 since it's a democratic system)
   */
  uint256 public constant ONE_VOTE = 1;

  /**
   * @notice The constructor for the GovernorDemocratic contract
   * @param _groupID The WorldID group ID, 1 for orb verification level
   * @param _worldIdRouter The WorldID router instance to obtain the WorldID contract address
   * @param _appId The World ID app ID
   * @param _actionId The World ID action ID
   * @param _name The governor name
   */
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    string memory _actionId,
    string memory _name
  ) GovernorWorldID(_groupID, _worldIdRouter, _appId, _actionId, _name) {}

  /**
   * @notice Returns 1 as the voting weight for the voter
   * @return _votingWeight 1 as voting weight
   */
  function _getVotes(address, uint256, bytes memory) internal view virtual override returns (uint256 _votingWeight) {
    return ONE_VOTE;
  }
}
