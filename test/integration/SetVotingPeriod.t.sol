// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationBase} from './IntegrationBase.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';

contract Integration_SetVotingPeriod is IntegrationBase {
  /**
   * @notice Test it correctly updates the voting period, and only this value
   */
  function test_setVotingPeriod(uint32 _newVotingPeriod) public {
    // Set the `votingPeriod` to a valid value
    uint256 _resetGracePeriodBefore = governance.resetGracePeriod();
    uint256 _rootExpirationThresholdBefore = governance.rootExpirationThreshold();
    uint256 _maxValidVotingPeriod = _resetGracePeriodBefore - _rootExpirationThresholdBefore - 1;
    _newVotingPeriod = uint32(bound(_newVotingPeriod, 1, _maxValidVotingPeriod));

    // Set the new config values
    vm.prank(address(governance));
    governance.setVotingPeriod(_newVotingPeriod);

    // Assert the voting period was correctly updated
    assertEq(governance.votingPeriod(), _newVotingPeriod);
    // Assert it was the only value updated
    assertEq(governance.resetGracePeriod(), _resetGracePeriodBefore);
    assertEq(governance.rootExpirationThreshold(), _rootExpirationThresholdBefore);
  }

  /**
   * @notice Test reverts when `votingPeriod` is greater than `resetGracePeriod` minus `rootExpirationThreshold`
   */
  function test_revertIfInvalidVotingPeriod() public {
    // Set the `votingPeriod` to an invalid value
    uint256 _maxValidVotingPeriod = governance.resetGracePeriod() - governance.rootExpirationThreshold() - 1;
    uint32 _newVotingPeriod = uint32(_maxValidVotingPeriod + 1);

    // Expect the call to revert
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidVotingPeriod.selector);
    vm.prank(address(governance));
    governance.setVotingPeriod(_newVotingPeriod);
  }
}
