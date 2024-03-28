// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from 'forge-std/Test.sol';
import {IWorldIDIdentityManager} from 'interfaces/IWorldIDIdentityManager.sol';

abstract contract UnitUtils is Test {
  /**
   * @notice Sets up a mock and expects a call to it*
   * @param _receiver The address to have a mock on
   * @param _calldata The calldata to mock and expect
   * @param _returned The data to return from the mocked call
   */
  function _mockAndExpect(address _receiver, bytes memory _calldata, bytes memory _returned) internal {
    vm.mockCall(_receiver, _calldata, _returned);
    vm.expectCall(_receiver, _calldata);
  }

  /**
   * @notice Mocks the WorldIDIdentityManager contract calls to `latestRoot` and `verifyRoot` and expects them to be called
   * @param _worldIDIdentityManager The WorldIDIdentityManager contract to mock and expect
   * @param _root The root to mock and expect
   * @param _nullifierHash The nullifier hash to mock and expect
   * @param _proof The proof to mock and expect
   * @param _rootExpirationThreshold The root expiration threshold to mock and expect
   * @param _rootTimestamp The root timestamp to mock and expect
   * @return _params The encoded parameters to mock and expect
   */
  function _mockWorlIDCalls(
    IWorldIDIdentityManager _worldIDIdentityManager,
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof,
    uint256 _rootExpirationThreshold,
    uint128 _rootTimestamp
  ) internal returns (bytes memory _params) {
    vm.assume(_root != 0);

    if (_rootExpirationThreshold == 0) {
      _mockAndExpect(
        address(_worldIDIdentityManager),
        abi.encodeWithSelector(IWorldIDIdentityManager.latestRoot.selector),
        abi.encode(_root)
      );
    } else {
      _mockAndExpect(
        address(_worldIDIdentityManager),
        abi.encodeWithSelector(IWorldIDIdentityManager.rootHistory.selector),
        abi.encode(_rootTimestamp)
      );
    }

    _mockAndExpect(
      address(_worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.verifyProof.selector),
      abi.encode(true)
    );

    // Encode the parameters
    _params = abi.encode(_root, _nullifierHash, _proof);
  }
}
