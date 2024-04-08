// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Deploy} from 'scripts/Deploy.sol';

contract DeploySepolia is Deploy {
  IWorldIDRouter public constant WORLD_ID_ROUTER = IWorldIDRouter(0x469449f251692E0779667583026b5A1E99512157);
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 0;

  string public appId = vm.envString('SEPOLIA_APP_ID');
  address public deployer = vm.rememberKey(vm.envUint('SEPOLIA_DEPLOYER_PK'));

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
