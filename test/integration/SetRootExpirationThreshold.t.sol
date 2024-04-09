// // SPDX-License-Identifier: MIT OR Apache-2.0
// pragma solidity 0.8.23;

// import {IntegrationBase} from './IntegrationBase.sol';
// import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
// import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';

// contract Integration_SetRootExpirationThreshold is IntegrationBase {
//   /**
//    * @notice Test `rootExpirationThreshold` is correctly updated, when the value is set to zero and non-zero.
//    */
//   function test_updateRootExpirationThreshold() public {
//     /* set to zero */
//     vm.startPrank(address(governance));
//     uint256 _previousRootExpirationThreshold = governance.rootExpirationThreshold();
//     uint256 _zero = 0;

//     vm.expectEmit(true, true, true, true, address(governance));
//     emit IGovernorWorldID.RootExpirationThresholdUpdated(_zero, rootExpirationThreshold);

//     governance.setRootExpirationThreshold(_zero);
//     uint256 _newRootExpirationThreshold = governance.rootExpirationThreshold();

//     assertTrue(_newRootExpirationThreshold != _previousRootExpirationThreshold);
//     assertEq(_newRootExpirationThreshold, _zero);

//     /* set to non-zero */
//     uint256 _currentRootExpirationThreshold = governance.rootExpirationThreshold();
//     uint256 _resetGracePeriod = governance.resetGracePeriod();
//     uint256 _rootHistoryExpiry = governance.WORLD_ID_ROUTER().routeFor(governance.GROUP_ID()).rootHistoryExpiry();
//     // The max value that the new root expiration threshold can be set to is the minimum between the root history
//     // expiry and the reset grace period
//     uint256 _maxValue = _rootHistoryExpiry < _resetGracePeriod ? _rootHistoryExpiry : _resetGracePeriod;
//     uint256 _nonZero = _maxValue - 1;

//     vm.expectEmit(true, true, true, true, address(governance));
//     emit IGovernorWorldID.RootExpirationThresholdUpdated(_nonZero, _currentRootExpirationThreshold);

//     governance.setRootExpirationThreshold(_nonZero);
//     _newRootExpirationThreshold = governance.rootExpirationThreshold();

//     assertTrue(_newRootExpirationThreshold != _currentRootExpirationThreshold);
//     assertEq(_newRootExpirationThreshold, _nonZero);
//   }

//   /**
//    * @notice Test reverts when `rootExpirationThreshold` is set to an invalid value.
//    */
//   function test_revertIfInvalidValue() public {
//     vm.startPrank(address(governance));

//     // try to update to a higher value than reset grace period
//     uint256 _newRootExpirationThreshold = governance.resetGracePeriod() + 1;
//     vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
//     governance.setRootExpirationThreshold(_newRootExpirationThreshold);

//     // Set the reset grace period to the maximum value so we are able to test the `rootHistoryExpiry` check
//     governance.setResetGracePeriod(type(uint256).max);

//     // try to update to a higher value than root expiration threshold
//     uint256 _rootHistoryExpiry = governance.WORLD_ID_ROUTER().routeFor(governance.GROUP_ID()).rootHistoryExpiry();
//     _newRootExpirationThreshold = _rootHistoryExpiry + 1;
//     vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
//     governance.setRootExpirationThreshold(_newRootExpirationThreshold);
//   }
// }
