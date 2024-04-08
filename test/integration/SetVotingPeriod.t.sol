// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationBase} from './IntegrationBase.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';

contract Integration_SetVotingPeriod is IntegrationBase {
  /**
   * @notice Test `votingPeriod` is correctly updated
   */
  function test_updateVotingPeriod() public {
    vm.startPrank(address(governance));

    uint256 _votingPeriodBefore = governance.votingPeriod();
    uint256 _resetGracePeriod = governance.resetGracePeriod();
    uint256 _rootExpirationThreshold = governance.rootExpirationThreshold();
    uint32 _newVotingPeriod = uint32(_resetGracePeriod - _rootExpirationThreshold - 1);

    vm.expectEmit(true, true, true, true, address(governance));
    emit GovernorSettings.VotingPeriodSet(_votingPeriodBefore, _newVotingPeriod);

    governance.setVotingPeriod(_newVotingPeriod);
    uint256 _votingPeriodAfter = governance.votingPeriod();

    assertTrue(_votingPeriodAfter != _votingPeriodBefore);
    assertEq(_votingPeriodAfter, _newVotingPeriod);
  }

  /**
   * @notice Test reverts when `votingPeriod` is set to an invalid value.
   */
  function test_revertIfInvalidValue() public {
    uint256 _resetGracePeriod = governance.resetGracePeriod();
    uint256 _rootExpirationThreshold = governance.rootExpirationThreshold();
    uint32 _newVotingPeriod = uint32(_resetGracePeriod - _rootExpirationThreshold + 1);

    vm.prank(address(governance));
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidVotingPeriod.selector);
    governance.setVotingPeriod(_newVotingPeriod);
  }
}
