// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import {IntegrationBase} from './IntegrationBase.sol';

import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';

contract Integration_SetResetGracePeriod is IntegrationBase {
  /**
   * @notice Test `resetGracePeriod` is correctly updated
   */
  function test_updateResetGracePeriod() public {
    vm.startPrank(address(governance));
    uint256 _previousResetGracePeriod = governance.resetGracePeriod();

    // Set to a new valid value
    uint256 _rootExpirationThreshold = governance.rootExpirationThreshold();
    uint256 _newResetGracePeriod;
    // Get a different value between the root expiration threshold and the current reset grace period
    _newResetGracePeriod = bound(_newResetGracePeriod, _rootExpirationThreshold, _previousResetGracePeriod - 1);

    vm.expectEmit(true, true, true, true);
    emit IGovernorWorldID.ResetGracePeriodUpdated(_newResetGracePeriod, _previousResetGracePeriod);

    governance.setResetGracePeriod(_newResetGracePeriod);
    uint256 _currentResetGracePeriod = governance.resetGracePeriod();

    assertTrue(_currentResetGracePeriod != _previousResetGracePeriod);
    assertEq(_currentResetGracePeriod, _newResetGracePeriod);
  }

  /**
   * @notice Test reverts when `resetGracePeriod` is set to an invalid value.
   */
  function test_revertIfInvalidValue() public {
    uint256 _newResetGracePeriod = governance.rootExpirationThreshold() - 1;
    vm.prank(address(governance));
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidResetGracePeriod.selector);
    governance.setResetGracePeriod(_newResetGracePeriod);
  }

  /**
   * @notice Test reverts when called by a non-governance address.
   */
  function test_revertIfNotGovernance() public {
    uint256 _randomNumber = 100_000;
    vm.prank(user);
    vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorOnlyExecutor.selector, user));
    governance.setResetGracePeriod(_randomNumber);
  }
}
