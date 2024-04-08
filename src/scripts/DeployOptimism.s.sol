// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Deploy} from 'scripts/Deploy.sol';

contract DeployOptimism is Deploy {
  IWorldIDRouter public constant WORLD_ID_ROUTER = IWorldIDRouter(0x57f928158C3EE7CDad1e4D8642503c4D0201f611);
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 1 hours;

  string public appId = vm.envString('OPTIMISM_APP_ID');
  address public deployer = vm.rememberKey(vm.envUint('OPTIMISM_DEPLOYER_PK'));

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
