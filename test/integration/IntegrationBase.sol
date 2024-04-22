// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import {DemocraticGovernance} from 'contracts/DemocraticGovernance.sol';
import {Test} from 'forge-std/Test.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

import 'forge-std/Test.sol';

contract IntegrationBase is Test {
  // Op block number on which the `ROOT` returned on the SDK was the latest one
  uint256 public constant FORK_BLOCK = 119_101_146;

  /* DAO constant settings */
  uint256 public constant QUORUM = 5;
  uint48 public constant INITIAL_VOTING_DELAY = 0;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 0;
  string public constant REASON = 'I want to vote on this proposal';

  // Worldcoin WorldID Id Router
  IWorldIDRouter public constant WORLD_ID_ROUTER = IWorldIDRouter(0x57f928158C3EE7CDad1e4D8642503c4D0201f611);
  /* Proof Inputs (on the SDK, everything was passed as a string) */
  string public constant APP_ID = 'app_40cfae76904f7231cf7dc28ce48a40e7';
  uint256 public constant PROPOSAL_ID =
    106_577_505_442_014_505_943_404_266_464_302_158_257_799_032_234_014_016_284_339_566_831_169_708_743_166;
  uint8 public constant FOR_SUPPORT = 1;
  uint256 public constant GROUP_ID = 1;

  /* Proof Outputs */
  // The root used to verify the proofs against. Is the same one for both proofs
  uint256 public constant ROOT = 0x2584efcf00afa67ba1ae71824a8bcc3251e701eac0a90989e4c5913b22b8af9f;
  // Nullifier hash returned on the first proof
  uint256 public constant NULLIFIER_HASH_ONE = 0x2c53c570a35d1be954f54e61e7cd5450a296da343d65526eece86f38fd160524;
  // Nullifier hash returned on the second proof
  uint256 public constant NULLIFIER_HASH_TWO = 0x2a159ced77346857b815e3a87b89e80c2053465d60f30f1ece8dbf0d64a0e948;

  // First proof
  uint256[8] public proofOne = [
    17_298_594_450_504_095_928_573_905_046_613_811_236_495_425_910_590_491_665_353_511_413_057_809_511_545,
    9_047_028_332_619_994_998_366_755_021_759_186_969_273_021_221_767_585_535_733_666_265_215_352_634_459,
    3_724_084_942_664_922_351_382_940_642_020_091_796_802_097_766_745_928_138_179_448_688_429_110_867_902,
    4_091_910_746_958_985_710_785_581_866_768_732_859_413_649_063_976_557_080_494_123_049_571_444_868_189,
    19_783_552_022_621_175_293_954_700_120_213_737_235_478_945_187_506_239_391_200_379_147_215_377_778_426,
    16_513_999_292_974_954_684_191_510_361_028_159_145_071_755_700_512_828_314_240_227_198_783_547_265_788,
    8_779_450_418_910_007_478_954_590_309_291_575_355_423_787_460_340_624_387_859_248_575_320_432_026_427,
    6_028_265_999_733_374_904_078_498_901_003_041_477_508_320_394_950_080_276_055_761_020_501_346_820_500
  ];
  // Second proof
  uint256[8] public proofTwo = [
    4_983_254_650_178_237_226_008_566_151_718_294_129_267_564_064_299_841_713_596_385_448_142_203_084_765,
    5_073_157_229_225_444_679_629_839_878_233_418_289_539_698_211_104_536_192_374_353_158_664_006_240_008,
    9_122_450_844_371_991_817_815_705_538_853_466_617_717_135_437_879_606_191_271_858_595_217_762_505_196,
    20_981_944_681_478_618_714_610_786_461_463_673_102_147_192_560_151_250_471_875_968_557_683_218_973_175,
    5_648_489_007_004_166_857_493_005_846_171_912_025_107_981_478_607_594_774_694_509_955_156_288_090_984,
    9_854_128_642_308_402_570_366_562_497_596_762_856_350_007_145_386_749_907_674_573_033_755_490_539_186,
    15_748_436_860_229_916_704_483_490_209_007_528_729_076_345_431_228_178_048_587_072_845_213_205_063_522,
    9_982_174_027_642_271_703_490_516_682_225_859_616_159_055_029_304_363_662_763_559_605_071_755_077_130
  ];

  // Root expiration threshold set to 1 hour so we test the `rootHistory` flow first
  uint256 public rootExpirationThreshold = 1 hours;
  // Contracts, addresses and other values
  DemocraticGovernance public governance;
  address public owner = makeAddr('owner');
  address public user = makeAddr('user');
  address public userTwo = makeAddr('userTwo');
  address public stranger = makeAddr('stranger');
  bytes public proofDataOne;
  bytes public proofDataTwo;
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
    address _wldOpAddr = 0xdC6fF44d5d932Cbd77B52E5612Ba0529DC6226F1;
    address _to = 0xD075Caa6e58702E028D0e43Cb796B73d23ab3eA5;
    uint256 _amount = 250 ether; // 18 decimals token
    address[] memory targets = new address[](1);
    targets[0] = _wldOpAddr;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = abi.encodeWithSignature('transfer(address,uint256)', _to, _amount);
    string memory description =
      'Donate 250WLD tokens to the Goat guy, so he can buy some more goats and build a shelter';

    vm.prank(owner);
    uint256 _proposalId = governance.propose(targets, values, calldatas, description);

    console.log('Proposal ID: %s', _proposalId);

    assert(_proposalId == PROPOSAL_ID);

    // Advance the time to make the proposal active
    vm.warp(block.timestamp + INITIAL_VOTING_DELAY + 1);

    // Pack all the first proof data together
    proofDataOne = abi.encodePacked(ROOT, NULLIFIER_HASH_ONE, proofOne);
    // Pack all the second proof data together
    proofDataTwo = abi.encodePacked(ROOT, NULLIFIER_HASH_TWO, proofTwo);
  }
}
