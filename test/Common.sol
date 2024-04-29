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
    22_442_797_494_261_953_658_866_970_562_382_695_381_374_791_900_609_510_781_343_806_702_515_143_895_416;
  uint8 public constant FOR_SUPPORT = 1;
  uint256 public constant GROUP_ID = 1;

  /* Proof One Data */
  uint256 public constant ROOT_ONE = 0x2826e08aee7890ce415f91b17d887069413510acf76f92516bf7b2cd61a15634;
  uint256 public constant NULLIFIER_HASH_ONE = 0x213c965b58ab09e7a6dcce4ad91a18150b35e6b58662ca3eb52ac458668f7668;
  // Block number at which the proof was generated
  uint256 public constant BLOCK_NUMBER_PROOF_ONE = 119_105_921;
  /* Proof Two Data */
  uint256 public constant ROOT_TWO = 0x14879f84f3b6c18712c84bbf7e932c9ce95015c63c312505f49b972f2da64655;
  uint256 public constant NULLIFIER_HASH_TWO = 0x2ff2a035de6db94279eceec995d103a6ab97cc1e37be6c09eb95be7ff9548618;
  // Block number at which the proof was generated
  uint256 public constant BLOCK_NUMBER_PROOF_TWO = 119_106_419;

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
    20_133_459_519_437_958_357_407_513_100_601_192_676_864_784_869_274_718_853_355_934_822_132_250_985_684,
    21_012_315_790_544_748_500_583_256_724_250_554_589_993_250_383_388_712_802_694_565_060_975_138_735_092,
    2_383_739_933_661_082_327_103_363_512_879_261_884_029_996_714_081_001_889_036_142_946_068_974_843_177,
    2_948_007_494_655_515_004_198_963_254_381_306_022_463_041_250_913_892_768_618_292_210_040_776_300_877,
    13_861_951_664_209_790_661_365_437_432_605_764_295_650_094_323_422_028_822_824_134_559_084_603_826_973,
    16_706_141_174_058_851_871_712_974_324_326_716_801_755_628_808_962_234_950_941_105_411_691_954_786_707,
    7_309_904_088_547_464_997_555_537_848_105_167_672_625_509_274_929_818_481_817_738_599_071_759_122_122,
    13_580_449_753_673_708_467_553_332_658_848_776_183_464_937_288_766_738_547_021_673_687_166_930_054_757
  ];
  // Second proof
  uint256[8] public proofTwo = [
    13_697_411_118_708_360_165_033_738_077_428_715_020_118_860_427_637_130_352_010_706_193_090_895_251_686,
    5_519_695_084_499_631_397_507_724_955_224_946_638_090_553_347_654_296_158_612_783_978_019_896_281_392,
    6_541_307_297_445_682_560_251_396_901_353_822_788_281_637_036_248_428_155_987_459_605_667_918_301_022,
    6_637_017_948_524_611_581_066_528_246_239_429_535_999_745_094_486_986_041_891_121_572_053_837_707_076,
    9_409_360_599_383_813_940_516_674_534_654_371_653_240_096_008_402_632_946_271_749_094_982_373_523_825,
    9_297_234_781_933_193_246_362_702_846_962_295_919_282_818_248_431_994_388_073_052_321_901_391_897_013,
    17_432_110_481_171_502_785_195_168_498_386_314_394_928_404_409_740_313_084_382_959_955_882_252_748_080,
    1_311_069_671_989_694_555_191_605_127_934_100_499_508_884_743_864_932_962_334_629_648_374_623_894_720
  ];

  // Fork block
  uint256 public forkBlock = BLOCK_NUMBER_PROOF_TWO;
  // Root expiration threshold set to 1 hour so we test the `rootHistory` flow first
  uint256 public rootExpirationThreshold = 1 hours;

  // Proposal description
  string public constant DESCRIPTION =
    'Donate 250WLD tokens to the Goat guy, so he can buy some more goats and build a shelter';
}
