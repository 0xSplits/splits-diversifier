// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "splits-tests/base.t.sol";

/* import {CreateOracleParams, IOracleFactory} from "splits-oracle/interfaces/IOracleFactory.sol"; */
import {ISplitMain} from "splits-utils/interfaces/ISplitMain.sol";
import {IUniswapV3Factory, UniV3OracleFactory} from "splits-oracle/UniV3OracleFactory.sol";
import {OracleImpl} from "splits-oracle/OracleImpl.sol";
import {PassThroughWalletImpl} from "splits-pass-through-wallet/PassThroughWalletImpl.sol";
import {PassThroughWalletFactory} from "splits-pass-through-wallet/PassThroughWalletFactory.sol";
import {SwapperImpl} from "splits-swapper/SwapperImpl.sol";
import {SwapperFactory} from "splits-swapper/SwapperFactory.sol";
import {UniV3OracleImpl} from "splits-oracle/UniV3OracleImpl.sol";
import {WalletImpl} from "splits-utils/WalletImpl.sol";

import {DiversifierFactory} from "../src/DiversifierFactory.sol";

// TODO: add oracle tests & revisit all others

// TODO: add constrained fuzzing utils for split creation params (e.g. len(acc) == len(alloc) && sum(alloc) == 1e6)
// TODO: add fuzzing

/* contract DiversifierFactoryTest is BaseTest { */
/*     event CreateDiversifier(address indexed diversifier); */
/*     event CreateSwapper(SwapperImpl indexed swapper, SwapperImpl.InitParams params); */

/*     ISplitMain splitMain; */
/*     UniV3OracleFactory oracleFactory; */
/*     SwapperFactory swapperFactory; */
/*     PassThroughWalletFactory passThroughWalletFactory; */

/*     DiversifierFactoryHarness diversifierFactory; */

/*     DiversifierFactory.RecipientParams[] recipients; */
/*     DiversifierFactory.RecipientParams recipient_isSwapper; */
/*     DiversifierFactory.RecipientParams recipient_isNotSwapper; */

/*     /\* CreateOracleParams createOracleParams; *\/ */
/*     SwapperImpl.InitParams swapperInit; */

/*     function setUp() public virtual override { */
/*         super.setUp(); */

/*         string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL"); */
/*         vm.createSelectFork(MAINNET_RPC_URL, BLOCK_NUMBER); */

/*         splitMain = ISplitMain(SPLIT_MAIN); */
/*         oracleFactory = new UniV3OracleFactory({ */
/*             uniswapV3Factory_: IUniswapV3Factory(UNISWAP_V3_FACTORY), */
/*             weth9_: WETH9 */
/*         }); */
/*         swapperFactory = new SwapperFactory(); */
/*         passThroughWalletFactory = new PassThroughWalletFactory(); */

/*         diversifierFactory = new DiversifierFactoryHarness({ */
/*             splitMain_: splitMain, */
/*             swapperFactory_: swapperFactory, */
/*             passThroughWalletFactory_: passThroughWalletFactory */
/*         }); */

/*         recipient_isNotSwapper = DiversifierFactory.RecipientParams({ */
/*             account: users.alice, */
/*             createSwapper: SwapperImpl.InitParams({ */
/*                 owner: ADDRESS_ZERO, */
/*                 paused: false, */
/*                 beneficiary: ADDRESS_ZERO, */
/*                 tokenToBeneficiary: ADDRESS_ZERO, */
/*                 oracle: OracleImpl(ADDRESS_ZERO) */
/*             }), */
/*             percentAllocation: 60_00_00 */
/*         }); */

/*         swapperInit = SwapperImpl.InitParams({ */
/*             owner: users.bob, */
/*             paused: false, */
/*             beneficiary: ADDRESS_ZERO, */
/*             tokenToBeneficiary: ADDRESS_ZERO, */
/*             oracle: OracleImpl(ADDRESS_ZERO) */
/*         }); */
/*         recipient_isSwapper = DiversifierFactory.RecipientParams({ */
/*             account: ADDRESS_ZERO, */
/*             createSwapper: swapperInit, */
/*             percentAllocation: 40_00_00 */
/*         }); */

/*         recipients.push(recipient_isNotSwapper); */
/*         recipients.push(recipient_isSwapper); */

/*         /\* createOracleParams = CreateOracleParams({ *\/ */
/*         /\*     factory: IOracleFactory(address(oracleFactory)), *\/ */
/*         /\*     data: abi.encode( *\/ */
/*         /\*         UniV3OracleImpl.InitParams({ *\/ */
/*         /\*             owner: users.alice, *\/ */
/*         /\*             defaultFee: 0, *\/ */
/*         /\*             defaultPeriod: 0, *\/ */
/*         /\*             defaultScaledOfferFactor: 0, *\/ */
/*         /\*             pairOverrides: new UniV3OracleImpl.SetPairOverrideParams[](0) *\/ */
/*         /\*         }) *\/ */
/*         /\*         ) *\/ */
/*         /\* }); *\/ */
/*     } */

/*     /// ----------------------------------------------------------------------- */
/*     /// tests - basic */
/*     /// ----------------------------------------------------------------------- */

/*     /// ----------------------------------------------------------------------- */
/*     /// tests - basic - createDiversifier */
/*     /// ----------------------------------------------------------------------- */

/*     function testFork_createDiversifier_createsPassThroughWallet_withCorrectOwner() public { */
/*         DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams(); */

/*         vm.expectCall({ */
/*             callee: address(passThroughWalletFactory), */
/*             msgValue: 0 ether, */
/*             data: abi.encodeCall( */
/*                 PassThroughWalletFactory.createPassThroughWallet, */
/*                 ( */
/*                     PassThroughWalletImpl.InitParams({ */
/*                         owner: address(diversifierFactory), */
/*                         paused: createDiversifierParams.paused, */
/*                         passThrough: ADDRESS_ZERO */
/*                     }) */
/*                 ) */
/*                 ) */
/*         }); */
/*         address diversifier = diversifierFactory.createDiversifier(createDiversifierParams); */
/*         assertEq(PassThroughWalletImpl(diversifier).$owner(), createDiversifierParams.owner); */
/*     } */

/*     function testFork_createDiversifier_createsSwappers_withCorrectOwner() public { */
/*         DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams(); */

/*         // create passThroughWallet to capture address & feed into fn via mock */
/*         PassThroughWalletImpl passThroughWallet = passThroughWalletFactory.createPassThroughWallet( */
/*             PassThroughWalletImpl.InitParams({ */
/*                 owner: address(diversifierFactory), */
/*                 paused: createDiversifierParams.paused, */
/*                 passThrough: ADDRESS_ZERO */
/*             }) */
/*         ); */

/*         vm.mockCall({ */
/*             callee: address(passThroughWalletFactory), */
/*             msgValue: 0, */
/*             data: abi.encodeCall( */
/*                 PassThroughWalletFactory.createPassThroughWallet, */
/*                 ( */
/*                     PassThroughWalletImpl.InitParams({ */
/*                         owner: address(diversifierFactory), */
/*                         paused: createDiversifierParams.paused, */
/*                         passThrough: ADDRESS_ZERO */
/*                     }) */
/*                 ) */
/*                 ), */
/*             returnData: abi.encode(passThroughWallet) */
/*         }); */

/*         recipient_isSwapper.createSwapper.owner = address(passThroughWallet); */
/*         vm.expectCall({ */
/*             callee: address(swapperFactory), */
/*             msgValue: 0 ether, */
/*             data: abi.encodeCall(SwapperFactory.createSwapper, (recipient_isSwapper.createSwapper)) */
/*         }); */
/*         diversifierFactory.createDiversifier(createDiversifierParams); */
/*     } */

/*     function testFork_createDiversifier_createsSplit() public { */
/*         DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams(); */

/*         // mock swapper return address */
/*         vm.mockCall({ */
/*             callee: address(swapperFactory), */
/*             msgValue: 0, */
/*             data: abi.encodeCall(SwapperFactory.createSwapper, (swapperInit)), */
/*             returnData: abi.encode(users.bob) */
/*         }); */

/*         // create passThroughWallet to capture address & feed into fn via mock */
/*         PassThroughWalletImpl passThroughWallet = passThroughWalletFactory.createPassThroughWallet( */
/*             PassThroughWalletImpl.InitParams({ */
/*                 owner: address(diversifierFactory), */
/*                 paused: createDiversifierParams.paused, */
/*                 passThrough: ADDRESS_ZERO */
/*             }) */
/*         ); */

/*         vm.mockCall({ */
/*             callee: address(passThroughWalletFactory), */
/*             msgValue: 0, */
/*             data: abi.encodeCall( */
/*                 PassThroughWalletFactory.createPassThroughWallet, */
/*                 ( */
/*                     PassThroughWalletImpl.InitParams({ */
/*                         owner: address(diversifierFactory), */
/*                         paused: createDiversifierParams.paused, */
/*                         passThrough: ADDRESS_ZERO */
/*                     }) */
/*                 ) */
/*                 ), */
/*             returnData: abi.encode(passThroughWallet) */
/*         }); */

/*         // sort createSplit params */
/*         address[] memory accounts = new address[](2); */
/*         // new swapper address is mock'd to return users.bob */
/*         (accounts[0], accounts[1]) = (createDiversifierParams.recipients[0].account, users.bob); */
/*         uint32[] memory percentAllocations = new uint32[](2); */
/*         (percentAllocations[0], percentAllocations[1]) = ( */
/*             createDiversifierParams.recipients[0].percentAllocation, */
/*             createDiversifierParams.recipients[1].percentAllocation */
/*         ); */
/*         if (users.alice > users.bob) { */
/*             (accounts[0], accounts[1]) = (users.bob, users.alice); */
/*             (percentAllocations[0], percentAllocations[1]) = (percentAllocations[1], percentAllocations[0]); */
/*         } */

/*         vm.expectCall({ */
/*             callee: address(splitMain), */
/*             msgValue: 0 ether, */
/*             data: abi.encodeCall(ISplitMain.createSplit, (accounts, percentAllocations, 0, address(passThroughWallet))) */
/*         }); */
/*         diversifierFactory.createDiversifier(createDiversifierParams); */
/*     } */

/*     function testFork_createDiversifier_createsSplit_withCorrectController() public { */
/*         DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams(); */

/*         address diversifier = diversifierFactory.createDiversifier(createDiversifierParams); */
/*         assertTrue(splitMain.getController(PassThroughWalletImpl(diversifier).$passThrough()) == diversifier); */
/*     } */

/*     function testFork_createDiversifier_emitsCreateDiversifier() public { */
/*         // don't check first topic which is new address */
/*         vm.expectEmit({checkTopic1: false, checkTopic2: true, checkTopic3: true, checkData: true}); */
/*         emit CreateDiversifier(ADDRESS_ZERO); */
/*         diversifierFactory.createDiversifier(_createDiversifierParams()); */
/*     } */

/*     /\* // TODO: check correct owner *\/ */
/*     /\* function testFork_createOracleAndDiversifier_createsOracle_withCorrectOwner() public { *\/ */
/*     /\*     vm.expectCall({ *\/ */
/*     /\*         callee: address(oracleFactory), *\/ */
/*     /\*         msgValue: 0 ether, *\/ */
/*     /\*         data: abi.encodeCall(IOracleFactory.createOracle, (createOracleParams.data)) *\/ */
/*     /\*     }); *\/ */
/*     /\*     diversifierFactory.createOracleAndDiversifier(_createOracleAndDiversifierParams()); *\/ */
/*     /\*     /\\* address diversifier = diversifierFactory.createOracleAndDiversifier(_createOracleAndDiversifierParams()); *\\/ *\/ */
/*     /\*     /\\* assertEq(oracle.$owner(), diversifier); *\\/ *\/ */
/*     /\* } *\/ */

/*     /\* function testFork_createOracleAndDiversifier_usesOracle() public { *\/ */
/*     /\*     vm.mockCall({ *\/ */
/*     /\*         callee: address(oracleFactory), *\/ */
/*     /\*         msgValue: 0, *\/ */
/*     /\*         data: abi.encodeWithSelector(IOracleFactory.createOracle.selector), *\/ */
/*     /\*         returnData: abi.encode(users.eve) *\/ */
/*     /\*     }); *\/ */
/*     /\*     swapperInit.oracle = OracleImpl(users.eve); *\/ */

/*     /\*     // don't check first topic which is new address *\/ */
/*     /\*     vm.expectEmit({checkTopic1: false, checkTopic2: true, checkTopic3: true, checkData: true}); *\/ */
/*     /\*     emit CreateSwapper(SwapperImpl(ADDRESS_ZERO), swapperInit); *\/ */
/*     /\*     diversifierFactory.createOracleAndDiversifier(_createOracleAndDiversifierParams()); *\/ */
/*     /\* } *\/ */

/*     /\* function testFork_createOracleAndDiversifier_emitsCreateDiversifier() public { *\/ */
/*     /\*     // don't check first topic which is new address *\/ */
/*     /\*     vm.expectEmit({checkTopic1: false, checkTopic2: true, checkTopic3: true, checkData: true}); *\/ */
/*     /\*     emit CreateDiversifier(ADDRESS_ZERO); *\/ */
/*     /\*     diversifierFactory.createOracleAndDiversifier(_createOracleAndDiversifierParams()); *\/ */
/*     /\* } *\/ */

/*     /// ----------------------------------------------------------------------- */
/*     /// tests - basic - _parseRecipientParams */
/*     /// ----------------------------------------------------------------------- */

/*     function testFork_parseRecipientParams() public { */
/*         DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams(); */

/*         address[] memory accounts = new address[](2); */
/*         // new swapper address is mock'd to return users.bob */
/*         (accounts[0], accounts[1]) = (createDiversifierParams.recipients[0].account, users.bob); */
/*         uint32[] memory percentAllocations = new uint32[](2); */
/*         (percentAllocations[0], percentAllocations[1]) = ( */
/*             createDiversifierParams.recipients[0].percentAllocation, */
/*             createDiversifierParams.recipients[1].percentAllocation */
/*         ); */

/*         vm.mockCall({ */
/*             callee: address(swapperFactory), */
/*             msgValue: 0, */
/*             data: abi.encodeCall(SwapperFactory.createSwapper, (swapperInit)), */
/*             returnData: abi.encode(users.bob) */
/*         }); */
/*         (address[] memory parsedAccounts, uint32[] memory parsedPercentAllocations) = */
/*             diversifierFactory.exposed_parseRecipientParams(recipients); */

/*         assertEq(parsedAccounts, accounts); */
/*         assertEq(parsedPercentAllocations, percentAllocations); */
/*     } */

/*     /// ----------------------------------------------------------------------- */
/*     /// tests - fuzz */
/*     /// ----------------------------------------------------------------------- */

/*     /// ----------------------------------------------------------------------- */
/*     /// tests - fuzz - _parseRecipientParams */
/*     /// ----------------------------------------------------------------------- */

/*     function testForkFuzz_parseRecipientParams(DiversifierFactory.RecipientParams[] memory recipients_) public { */
/*         uint256 length = recipients_.length; */
/*         address[] memory accounts = new address[](length); */
/*         uint32[] memory percentAllocations = new uint32[](length); */
/*         // new swapper addresses are mock'd to return their index */
/*         for (uint256 i; i < length; i++) { */
/*             DiversifierFactory.RecipientParams memory recipient = recipients_[i]; */
/*             percentAllocations[i] = recipient.percentAllocation; */
/*             if (recipient.account != ADDRESS_ZERO) { */
/*                 accounts[i] = recipient.account; */
/*             } else { */
/*                 address mockSwapper = address(bytes20(keccak256(abi.encode(recipient.createSwapper)))); */
/*                 accounts[i] = mockSwapper; */
/*                 vm.mockCall({ */
/*                     callee: address(swapperFactory), */
/*                     msgValue: 0, */
/*                     data: abi.encodeCall(SwapperFactory.createSwapper, (recipient.createSwapper)), */
/*                     returnData: abi.encode(mockSwapper) */
/*                 }); */
/*             } */
/*         } */

/*         (address[] memory parsedAccounts, uint32[] memory parsedPercentAllocations) = */
/*             diversifierFactory.exposed_parseRecipientParams(recipients_); */

/*         assertEq(parsedAccounts, accounts); */
/*         assertEq(parsedPercentAllocations, percentAllocations); */
/*     } */

/*     /// ----------------------------------------------------------------------- */
/*     /// internal */
/*     /// ----------------------------------------------------------------------- */

/*     /// @dev can't be init'd in setUp & saved to storage bc of nested dynamic array solc error */
/*     /// UnimplementedFeatureError: Copying of type struct DiversifierFactory.RecipientParams memory[] memory to storage not yet supported. */
/*     function _createDiversifierParams() internal view returns (DiversifierFactory.CreateDiversifierParams memory) { */
/*         return DiversifierFactory.CreateDiversifierParams({owner: users.alice, paused: false, recipients: recipients}); */
/*     } */
/* } */

/* contract DiversifierFactoryHarness is DiversifierFactory { */
/*     constructor( */
/*         ISplitMain splitMain_, */
/*         SwapperFactory swapperFactory_, */
/*         PassThroughWalletFactory passThroughWalletFactory_ */
/*     ) DiversifierFactory(splitMain_, swapperFactory_, passThroughWalletFactory_) {} */

/*     function exposed_parseRecipientParams(DiversifierFactory.RecipientParams[] memory recipients_) */
/*         external */
/*         returns (address[] memory, uint32[] memory) */
/*     { */
/*         return _parseRecipientParams(recipients_); */
/*     } */
/* } */
