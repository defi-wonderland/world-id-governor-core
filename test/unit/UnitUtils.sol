// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from 'forge-std/Test.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldIDIdentityManager} from 'interfaces/IWorldIDIdentityManager.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {Strings} from 'open-zeppelin/utils/Strings.sol';

abstract contract UnitUtils is Test {
  using Strings for uint256;
  using ByteHasher for bytes;

  uint256 internal constant _GROUP_ID = 1;
  IWorldIDRouter internal _worldIDRouter = IWorldIDRouter(makeAddr('worldIDRouter'));
  IWorldIDIdentityManager internal _worldIDIdentityManager = IWorldIDIdentityManager(makeAddr('worldIDIdentityManager'));

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
   * @notice Mocks the WorldIDIdentityManager contract calls to `latestRoot` or `rootHistory`, and `verifyRoot`
   *  and expects them to be called
   * @param _governor The governor contract to interact with
   * @param _support The support need for the signal hash to mock and expect
   * @param _proposalId The proposal ID need for the external nullifier hash to mock and expect
   * @param _root The root to mock and expect
   * @param _nullifierHash The nullifier hash to mock and expect
   * @param _proof The proof to mock and expect
   * @param _rootExpirationThreshold The root expiration threshold to mock and expect
   * @param _rootTimestamp The root timestamp to mock and expect
   * @return _params The encoded parameters to mock and expect
   */
  function _mockWorlIDCalls(
    IGovernorWorldID _governor,
    uint8 _support,
    uint256 _proposalId,
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

    // Mock the `verifyProof` function and expect it to be called
    uint256 _signalHash = abi.encodePacked(uint256(_support).toString()).hashToField();
    uint256 _externalNullifierHash = abi.encodePacked(_governor.APP_ID_HASH(), _proposalId.toString()).hashToField();
    _mockAndExpect(
      address(_worldIDRouter),
      abi.encodeWithSelector(
        IWorldIDRouter.verifyProof.selector,
        _root,
        _GROUP_ID,
        _signalHash,
        _nullifierHash,
        _externalNullifierHash,
        _proof
      ),
      abi.encode(true)
    );

    // Encode the parameters
    _params = abi.encode(_root, _nullifierHash, _proof);
  }
}
