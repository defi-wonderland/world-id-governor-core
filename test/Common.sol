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
  uint256 public constant ROOT_ONE = 0x040bdd42ee2ffc018d70cb6ca24bb0e347b55eb4af03cb20611b3eb810b1798c;
  uint256 public constant NULLIFIER_HASH_ONE = 0x19935b80c19b28c6a2fda6b13efa3ba5fd13c060435e94eccb2fa4bc2047d4ae;
  // Block number at which the proof was generated
  uint256 public constant BLOCK_NUMBER_PROOF_ONE = 119_405_418;
  /* Proof Two Data */
  uint256 public constant ROOT_TWO = 0x16333c73ae50180e8576d74233bd8f2ef3cecd749062101d4d72c635708d90b4;
  uint256 public constant NULLIFIER_HASH_TWO = 0x1bd406a6d5202928a0fe00d6c339d1f38067c65657237d4a6939cc3d6cffdfe7;
  // Block number at which the proof was generated
  uint256 public constant BLOCK_NUMBER_PROOF_TWO = 119_407_745;

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
    4_293_265_005_994_428_676_847_250_984_285_858_942_533_817_606_506_338_240_464_969_133_170_085_090_627,
    10_902_098_557_575_990_095_572_986_747_576_070_806_567_609_361_818_086_586_879_649_424_035_610_397_320,
    18_043_548_553_303_464_876_858_044_988_849_837_475_934_029_862_879_752_769_346_078_325_825_735_254_702,
    3_418_311_490_772_437_751_872_808_402_052_487_745_352_226_223_999_403_233_693_083_547_802_398_329_518,
    12_919_034_426_809_387_651_980_265_261_304_080_224_056_421_948_433_618_087_349_441_357_253_453_727_536,
    10_810_176_363_076_199_135_666_577_708_987_337_617_073_066_213_490_042_751_500_178_406_830_708_600_490,
    8_151_432_487_163_653_362_620_562_978_972_141_517_924_875_175_222_334_241_025_023_576_217_949_389_545,
    11_630_063_488_837_794_149_265_445_675_582_649_333_060_634_561_843_487_981_637_887_383_363_646_093_231
  ];
  // Second proof
  uint256[8] public proofTwo = [
    1_526_972_530_030_399_802_006_921_315_048_352_356_058_989_950_514_622_890_916_218_666_577_146_801_104,
    17_827_750_725_680_091_529_881_728_396_221_533_594_459_404_503_412_132_571_877_491_971_881_314_011_529,
    19_798_038_159_122_422_653_410_006_746_732_773_723_974_784_067_849_651_926_623_632_453_844_054_439_777,
    5_701_212_658_938_943_390_555_348_893_044_722_641_649_102_816_991_834_288_101_311_925_782_848_989_046,
    21_717_121_320_990_285_473_678_978_189_571_935_656_367_006_312_215_565_811_250_101_009_994_753_484_999,
    13_152_505_911_439_773_934_809_745_448_326_725_125_295_738_159_306_805_728_313_816_575_173_474_184_437,
    8_418_653_335_008_313_931_056_642_967_648_106_002_907_728_402_293_742_811_509_813_836_322_024_901_778,
    21_344_512_652_619_822_005_843_818_055_079_437_828_436_470_360_088_366_445_744_569_456_042_209_724_123
  ];

  // Fork block
  uint256 public forkBlock = BLOCK_NUMBER_PROOF_TWO;
  // Root expiration threshold set to 2 hours so we test the `rootHistory` flow first
  uint256 public rootExpirationThreshold = 2 hours;

  // Proposal description
  string public constant DESCRIPTION = 'Should Wonderland contribute 250 WLD to Richard\'s goat project?';
}
