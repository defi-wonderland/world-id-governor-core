// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import {DemocraticGovernance} from 'contracts/DemocraticGovernance.sol';
import {Test} from 'forge-std/Test.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

import 'forge-std/Test.sol';

contract IntegrationBase is Test {
  /* DAO constant settings */
  uint256 public constant QUORUM = 5;
  uint48 public constant INITIAL_VOTING_DELAY = 0;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 0;
  string public constant REASON = 'I want to vote on this proposal';

  // Worldcoin WorldID Id Router
  IWorldIDRouter public constant WORLD_ID_ROUTER = IWorldIDRouter(0x57f928158C3EE7CDad1e4D8642503c4D0201f611);

  // Op block number on which the `ROOT` returned on the SDK was the latest one
  uint256 public constant FORK_BLOCK = 118_985_674;

  /* Proof Inputs (on the SDK, everything was passed as a string) */
  string public constant APP_ID = 'app_40cfae76904f7231cf7dc28ce48a40e7';
  uint256 public constant PROPOSAL_ID =
    51_384_813_360_217_536_574_306_829_156_715_988_407_631_161_679_419_797_722_877_853_216_538_059_873_527;
  uint8 public constant FOR_SUPPORT = 1;
  uint256 public constant GROUP_ID = 1;

  /* Proof Outputs */
  uint256 public constant ROOT = 0x1439b1b8294e4bfe71a81c29daa378947b8d35dfc9faffe1debb6f8d206f48f5;
  uint256 public constant NULLIFIER_HASH = 0x1bf6089762e46ab249c0f9bc0c22abbe4899242e8a26100a9bd8b2930d959c24;

  uint256[8] public proof = [
    3_760_598_054_540_594_155_029_024_146_631_356_293_075_449_310_750_183_967_209_540_083_464_580_805_636,
    14_266_988_862_502_978_857_050_537_875_878_333_925_982_355_850_577_134_788_643_719_311_387_202_613_638,
    17_873_660_279_405_525_056_302_559_996_088_651_413_064_182_719_356_902_638_215_452_965_177_623_394_966,
    21_736_299_499_104_254_386_576_981_348_601_493_571_392_056_631_833_464_029_184_838_065_221_924_752_655,
    15_787_026_394_355_203_071_521_523_844_939_361_024_486_617_581_670_194_364_947_511_686_465_884_280_370,
    20_532_460_566_312_490_442_475_878_880_610_515_425_992_179_120_150_991_150_240_322_255_624_195_925_212,
    6_537_684_568_486_212_583_837_058_966_639_634_826_708_352_721_970_088_019_204_610_021_119_760_399_401,
    7_331_490_139_911_688_804_012_066_906_648_538_202_966_281_497_035_287_928_547_886_203_592_112_338_875
  ];

  // Root expiration threshold set to 1 hour so we test the `rootHistory` flow first
  uint256 public rootExpirationThreshold = 1 hours;
  // Contracts, addresses and other values
  DemocraticGovernance public governance;
  address public owner = makeAddr('owner');
  address public user = makeAddr('user');
  address public stranger = makeAddr('stranger');
  bytes public proofData;
  uint256 public forkId;

  function setUp() public virtual {
    forkId = vm.createSelectFork(vm.rpcUrl('optimism'), FORK_BLOCK);

    // Deploy a DemocraticGovernance instance
    vm.prank(owner);
    governance = new DemocraticGovernance(
      GROUP_ID,
      WORLD_ID_ROUTER,
      APP_ID,
      QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      rootExpirationThreshold
    );

    // Create a proposal that matches the proposal id used as action id when generating the proof
    address[] memory targets = new address[](1);
    targets[0] = address(0);
    uint256[] memory values = new uint256[](1);
    values[0] = 1 ether;
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = '';
    string memory description = 'Burn an eth';

    vm.prank(owner);
    uint256 _proposalId = governance.propose(targets, values, calldatas, description);
    console.log('Proposal ID:', _proposalId);
    console.log('Expected Proposal ID:', PROPOSAL_ID);
    assert(_proposalId == PROPOSAL_ID);

    // Advance the time to make the proposal active
    vm.warp(block.timestamp + INITIAL_VOTING_DELAY + 1);

    // Pack the all the proof data together
    proofData = abi.encodePacked(ROOT, NULLIFIER_HASH, proof);
  }
}
