// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

contract Common {
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
    20_261_653_924_289_286_028_884_754_682_055_703_278_899_359_147_134_906_975_799_268_095_826_480_486_592;
  uint8 public constant FOR_SUPPORT = 1;
  uint256 public constant GROUP_ID = 1;

  /* Proof One Data */
  uint256 public constant ROOT_ONE = 0x16333c73ae50180e8576d74233bd8f2ef3cecd749062101d4d72c635708d90b4;
  uint256 public constant NULLIFIER_HASH_ONE = 0x1bd406a6d5202928a0fe00d6c339d1f38067c65657237d4a6939cc3d6cffdfe7;
  // Block number at which the proof was generated
  uint256 public constant BLOCK_NUMBER_PROOF_ONE = 119_407_745;
  /* Proof Two Data */
  uint256 public constant ROOT_TWO = 0x2f88ab2f5a3c16a5237e1ddb4f5b2e15fdbf3af51003af7f8bd1947b799a1026;
  uint256 public constant NULLIFIER_HASH_TWO = 0x19935b80c19b28c6a2fda6b13efa3ba5fd13c060435e94eccb2fa4bc2047d4ae;
  // Block number at which the proof was generated
  uint256 public constant BLOCK_NUMBER_PROOF_TWO = 119_409_201;

  // WLD Token
  address public constant WLD = 0xdC6fF44d5d932Cbd77B52E5612Ba0529DC6226F1;

  // WLD holder
  address public constant WLD_HOLDER = 0xacD03D601e5bB1B275Bb94076fF46ED9D753435A;

  // Goat Guy address
  address public constant GOAT_GUY = 0xD075Caa6e58702E028D0e43Cb796B73d23ab3eA5;

  // Transfer amount
  uint256 public constant WLD_AMOUNT = 250 ether;

  // First proof
  uint256[8] public proofOne = [
    1_526_972_530_030_399_802_006_921_315_048_352_356_058_989_950_514_622_890_916_218_666_577_146_801_104,
    17_827_750_725_680_091_529_881_728_396_221_533_594_459_404_503_412_132_571_877_491_971_881_314_011_529,
    19_798_038_159_122_422_653_410_006_746_732_773_723_974_784_067_849_651_926_623_632_453_844_054_439_777,
    5_701_212_658_938_943_390_555_348_893_044_722_641_649_102_816_991_834_288_101_311_925_782_848_989_046,
    21_717_121_320_990_285_473_678_978_189_571_935_656_367_006_312_215_565_811_250_101_009_994_753_484_999,
    13_152_505_911_439_773_934_809_745_448_326_725_125_295_738_159_306_805_728_313_816_575_173_474_184_437,
    8_418_653_335_008_313_931_056_642_967_648_106_002_907_728_402_293_742_811_509_813_836_322_024_901_778,
    21_344_512_652_619_822_005_843_818_055_079_437_828_436_470_360_088_366_445_744_569_456_042_209_724_123
  ];
  // Second proof
  uint256[8] public proofTwo = [
    17_121_492_102_403_312_317_592_247_846_589_682_911_004_623_501_352_788_546_241_781_288_581_047_879_165,
    1_863_024_362_292_055_097_989_049_526_996_905_822_595_418_207_634_016_985_741_425_366_034_310_482_353,
    11_790_736_632_047_908_248_651_171_769_793_082_239_923_716_051_738_708_110_867_227_539_852_627_920_942,
    21_805_840_689_046_294_806_327_803_520_283_197_035_252_676_878_264_693_889_332_874_629_293_858_935_969,
    20_214_795_142_291_227_296_317_335_213_139_835_506_453_497_340_213_748_634_530_216_345_614_755_321_814,
    5_824_525_387_804_642_099_180_597_154_278_114_786_338_594_443_750_295_900_058_486_235_159_752_684_338,
    19_040_881_847_948_053_265_152_788_860_646_729_569_507_808_063_074_301_802_291_997_757_311_654_238_879,
    3_957_369_849_563_076_484_229_791_470_194_111_879_721_319_439_726_862_948_842_870_281_772_477_657_567
  ];

  // Fork block
  uint256 public forkBlock = BLOCK_NUMBER_PROOF_TWO;
  // Root expiration threshold set to 1 hour so we test the `rootHistory` flow first
  uint256 public rootExpirationThreshold = 1 hours;

  // Proposal description
  string public constant DESCRIPTION = 'Should Wonderland contribute 250 WLD to Richard\'s goat project?';
}
