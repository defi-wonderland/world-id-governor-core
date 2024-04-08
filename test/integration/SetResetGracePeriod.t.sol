// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import {Common} from './Common.sol';

import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';

contract Integration_SetResetGracePeriod is Common {
  /**
   * @notice Test `resetGracePeriod` is correctly updated
   */
  function test_updateResetGracePeriod() public {
    /* set to zero */
    vm.startPrank(address(governance));
    uint256 _firstResetGracePeriod = governance.resetGracePeriod();
    uint256 _rootExpirationThreshold = governance.rootExpirationThreshold();
    uint256 _newResetGracePeriod;
    _newResetGracePeriod = bound(_newResetGracePeriod, _rootExpirationThreshold, _firstResetGracePeriod - 1);

    vm.expectEmit(true, true, true, true);
    emit IGovernorWorldID.ResetGracePeriodUpdated(_newResetGracePeriod, _firstResetGracePeriod);

    governance.setResetGracePeriod(_newResetGracePeriod);
    uint256 _resetGracePeriod = governance.rootExpirationThreshold();

    assertTrue(_resetGracePeriod != _firstResetGracePeriod);
    assertEq(_resetGracePeriod, _newResetGracePeriod);
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
