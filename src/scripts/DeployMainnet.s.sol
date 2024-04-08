// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Deploy} from 'scripts/Deploy.sol';

contract DeployMainnet is Deploy {
  IWorldIDRouter public constant WORLD_ID_ROUTER = IWorldIDRouter(0x163b09b4fE21177c455D850BD815B6D583732432);
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 0;

  string public appId = vm.envString('MAINNET_APP_ID');
  address public deployer = vm.rememberKey(vm.envUint('MAINNET_DEPLOYER_PK'));

  function run() public {
    vm.startBroadcast(deployer);

    // Deploy DemocraticGovernance
    _deploy(
      GROUP_ID,
      WORLD_ID_ROUTER,
      appId,
      QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      ROOT_EXPIRATION_THRESHOLD
    );

    vm.stopBroadcast();
  }
}
