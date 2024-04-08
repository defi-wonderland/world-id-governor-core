// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Deploy} from 'scripts/Deploy.sol';

contract DeployOpSepolia is Deploy {
  uint256 public constant GROUP_ID = 1;
  IWorldIDRouter public constant WORLD_ID_ROUTER = IWorldIDRouter(0x11cA3127182f7583EfC416a8771BD4d11Fae4334);
  uint256 public constant QUORUM = 5;
  uint48 public constant INITIAL_VOTING_DELAY = 0;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 0;
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 1 hours;

  string public appId = vm.envString('OPSEPOLIA_APP_ID');
  address public deployer = vm.rememberKey(vm.envUint('OPSEPOLIA_DEPLOYER_PK'));

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
