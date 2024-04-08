// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DemocraticGovernance} from 'contracts/DemocraticGovernance.sol';
import {Script, console} from 'forge-std/Script.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

contract DeployOptimism is Script {
  uint256 public constant GROUP_ID = 1;
  IWorldIDRouter public constant WORLD_ID_ROUTER = IWorldIDRouter(0x57f928158C3EE7CDad1e4D8642503c4D0201f611);
  uint256 public constant QUORUM = 5;
  uint48 public constant INITIAL_VOTING_DELAY = 0;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 0;
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 1 hours;

  string public appId = vm.envString('OPTIMISM_APP_ID');
  address public deployer = vm.rememberKey(vm.envUint('OPTIMISM_DEPLOYER_PK'));

  function run() public {
    vm.startBroadcast(deployer);

    // Deploy DemocraticGovernance
    DemocraticGovernance _democraticGovernance = new DemocraticGovernance(
      GROUP_ID,
      WORLD_ID_ROUTER,
      appId,
      QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      ROOT_EXPIRATION_THRESHOLD
    );
    console.log('Democratic Governance deployed at:', address(_democraticGovernance));

    vm.stopBroadcast();
  }
}
