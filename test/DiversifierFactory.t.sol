// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "splits-tests/base.t.sol";

import {IOracleFactory} from "splits-oracle/interfaces/IOracleFactory.sol";
import {ISplitMain} from "splits-utils/interfaces/ISplitMain.sol";
import {IUniswapV3Factory, UniV3OracleFactory} from "splits-oracle/UniV3OracleFactory.sol";
import {OracleImpl} from "splits-oracle/OracleImpl.sol";
import {OracleParams} from "splits-oracle/peripherals/OracleParams.sol";
import {PassThroughWalletImpl} from "splits-pass-through-wallet/PassThroughWalletImpl.sol";
import {PassThroughWalletFactory} from "splits-pass-through-wallet/PassThroughWalletFactory.sol";
import {SwapperImpl} from "splits-swapper/SwapperImpl.sol";
import {SwapperFactory} from "splits-swapper/SwapperFactory.sol";
import {UniV3OracleImpl} from "splits-oracle/UniV3OracleImpl.sol";
import {WalletImpl} from "splits-utils/WalletImpl.sol";

import {DiversifierFactory} from "../src/DiversifierFactory.sol";

// TODO: add tests for oracle params
// TODO: revisit tests for recipient params

// TODO: add constrained fuzzing utils for split creation params (e.g. len(acc) == len(alloc) && sum(alloc) == 1e6)
// TODO: add fuzzing

contract DiversifierFactoryTest is BaseTest {
    using AddressUtils for address;

    event CreateDiversifier(address indexed diversifier);
    event CreateSwapper(SwapperImpl indexed swapper, SwapperFactory.CreateSwapperParams params);

    ISplitMain splitMain;
    UniV3OracleFactory oracleFactory;
    SwapperFactory swapperFactory;
    PassThroughWalletFactory passThroughWalletFactory;

    DiversifierFactoryHarness diversifierFactory;

    DiversifierFactory.RecipientParams[] recipientParams;
    DiversifierFactory.RecipientParams recipientAlice;
    DiversifierFactory.RecipientParams recipientSwapperBob;
    DiversifierFactory.RecipientParams recipientSwapperEve;

    OracleParams oracleParams;
    UniV3OracleImpl.InitParams initOracleParams;

    function setUp() public virtual override {
        super.setUp();

        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(MAINNET_RPC_URL, BLOCK_NUMBER);

        splitMain = ISplitMain(SPLIT_MAIN);
        oracleFactory = new UniV3OracleFactory({
            uniswapV3Factory_: IUniswapV3Factory(UNISWAP_V3_FACTORY),
            weth9_: WETH9
        });
        swapperFactory = new SwapperFactory();
        passThroughWalletFactory = new PassThroughWalletFactory();

        diversifierFactory = new DiversifierFactoryHarness({
            splitMain_: splitMain,
            swapperFactory_: swapperFactory,
            passThroughWalletFactory_: passThroughWalletFactory
        });

        recipientAlice.account = users.alice;
        recipientAlice.percentAllocation = 20_00_00;

        recipientSwapperBob.createSwapperParams.beneficiary = users.bob;
        recipientSwapperBob.createSwapperParams.tokenToBeneficiary = address(mockERC20);
        recipientSwapperBob.percentAllocation = 40_00_00;

        recipientSwapperEve.createSwapperParams.beneficiary = users.eve;
        recipientSwapperEve.createSwapperParams.tokenToBeneficiary = ETH_ADDRESS;
        recipientSwapperEve.percentAllocation = 40_00_00;

        recipientParams.push(recipientAlice);
        recipientParams.push(recipientSwapperBob);
        recipientParams.push(recipientSwapperEve);

        initOracleParams.owner = users.alice;

        oracleParams.createOracleParams.factory = IOracleFactory(address(oracleFactory));
        oracleParams.createOracleParams.data = abi.encode(initOracleParams);
    }

    /// -----------------------------------------------------------------------
    /// tests - basic
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// tests - basic - createDiversifier
    /// -----------------------------------------------------------------------

    /// testing tree

    // it should create a pass-through wallet
    ///  with the owner from args
    ///  with a split pass-through
    // it shouldn't create an oracle if given one
    // it should create an oracle if not given one
    // it should create swappers
    //  with diversifier owner
    //  with oracle from args, if provided
    //  with new oracle from factory args, if oracle not provided
    // it should create a split
    //  with diversifier controller
    //  with recipients from args

    /// @dev it should create a pass-through wallet
    function testFork_createDiversifier_createsPassThroughWallet() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        vm.expectCall({
            callee: address(passThroughWalletFactory),
            msgValue: 0 ether,
            data: abi.encodeCall(
                PassThroughWalletFactory.createPassThroughWallet,
                (
                    PassThroughWalletImpl.InitParams({
                        owner: address(diversifierFactory),
                        paused: createDiversifierParams.paused,
                        passThrough: ADDRESS_ZERO
                    })
                )
                )
        });
        diversifierFactory.createDiversifier(createDiversifierParams);
    }

    /// @dev it should create a pass-through wallet with the owner from args
    function testFork_createDiversifier_createsPassThroughWallet_withOwnerFromArgs() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();
        address diversifier = diversifierFactory.createDiversifier(createDiversifierParams);
        assertEq(PassThroughWalletImpl(diversifier).owner(), createDiversifierParams.owner);
    }

    /// @dev it should create a pass-through wallet with a split pass-through
    function testFork_createDiversifier_createsPassThroughWallet_withSplitPassThrough() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        address expectedSplit = _predictNextAddressFrom(address(splitMain));
        address diversifier = diversifierFactory.createDiversifier(createDiversifierParams);
        assertTrue(splitMain.getHash(PassThroughWalletImpl(diversifier).passThrough()) != bytes32(0));
        assertEq(PassThroughWalletImpl(diversifier).passThrough(), expectedSplit);
    }

    /// @dev it shouldn't create an oracle if given one
    function testFork_createDiversifier_notCreateOracleWhenProvidedOne() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();
        createDiversifierParams.oracleParams.oracle = OracleImpl(users.alice);
        uint64 preCallOracleFactoryNonce = vm.getNonce(address(oracleFactory));
        diversifierFactory.createDiversifier(createDiversifierParams);
        uint64 postCallOracleFactoryNonce = vm.getNonce(address(oracleFactory));
        assertEq(preCallOracleFactoryNonce, postCallOracleFactoryNonce);
    }

    /// @dev it shouldn't create an oracle if given one
    function testFailFork_createDiversifier_notCreateOracleWhenProvidedOne() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();
        createDiversifierParams.oracleParams.oracle = OracleImpl(users.alice);
        vm.expectCall({callee: address(oracleFactory), data: ""});
        diversifierFactory.createDiversifier(createDiversifierParams);
    }

    /// @dev it should create an oracle if not given one
    function testFork_createDiversifier_createsOracleWhenNotProvidedOne() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        vm.expectCall({
            callee: address(oracleFactory),
            msgValue: 0 ether,
            data: abi.encodeWithSignature("createOracle(bytes)", abi.encode(initOracleParams))
        });
        diversifierFactory.createDiversifier(createDiversifierParams);
    }

    /// @dev it should create swappers
    function testFork_createDiversifier_createsSwappers() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        address expectedPassThroughWallet = _predictNextAddressFrom(address(passThroughWalletFactory));
        createDiversifierParams.oracleParams.oracle = OracleImpl(users.alice);
        OracleParams memory swapperOracleParams;
        swapperOracleParams.oracle = OracleImpl(users.alice);

        uint256 length = recipientParams.length;
        for (uint256 i; i < length; i++) {
            DiversifierFactory.RecipientParams memory rp = recipientParams[i];
            if (rp.account._isEmpty()) {
                vm.expectCall({
                    callee: address(swapperFactory),
                    msgValue: 0 ether,
                    data: abi.encodeCall(
                        SwapperFactory.createSwapper,
                        (
                            SwapperFactory.CreateSwapperParams({
                                owner: expectedPassThroughWallet,
                                paused: false,
                                beneficiary: rp.createSwapperParams.beneficiary,
                                tokenToBeneficiary: rp.createSwapperParams.tokenToBeneficiary,
                                oracleParams: swapperOracleParams
                            })
                        )
                        )
                });
            }
        }
        diversifierFactory.createDiversifier(createDiversifierParams);
    }

    /// @dev it should create swappers with diversifier owner
    function testFork_createDiversifier_createsSwappers_withDiversifierOwner() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        address[] memory expectedSwappers = _predictNextAddressesFrom(address(swapperFactory), 2);

        address diversifier = diversifierFactory.createDiversifier(createDiversifierParams);
        for (uint256 i; i < expectedSwappers.length; i++) {
            assertEq(SwapperImpl(expectedSwappers[i]).owner(), diversifier);
        }
    }

    /// @dev it should create swappers with oracle from args, if provided
    function testFork_createDiversifier_createsSwappers_withOracleFromArgs() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();
        createDiversifierParams.oracleParams.oracle = OracleImpl(users.alice);

        address[] memory expectedSwappers = _predictNextAddressesFrom(address(swapperFactory), 2);

        diversifierFactory.createDiversifier(createDiversifierParams);
        for (uint256 i; i < expectedSwappers.length; i++) {
            assertEq(address(SwapperImpl(expectedSwappers[i]).$oracle()), users.alice);
        }
    }

    /// @dev it should create swappers with new oracle from factory args, if oracle not provided
    function testFork_createDiversifier_createsSwappers_withNewOracle() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        address expectedOracle = _predictNextAddressFrom(address(oracleFactory));
        address[] memory expectedSwappers = _predictNextAddressesFrom(address(swapperFactory), 2);

        diversifierFactory.createDiversifier(createDiversifierParams);
        for (uint256 i; i < expectedSwappers.length; i++) {
            assertEq(address(SwapperImpl(expectedSwappers[i]).$oracle()), expectedOracle);
        }
    }

    /// @dev it should create a split
    function testFork_createDiversifier_createsSplit() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        address expectedPassThroughWallet = _predictNextAddressFrom(address(passThroughWalletFactory));

        createDiversifierParams.recipientParams = new DiversifierFactory.RecipientParams[](2);

        recipientAlice.account = users.alice;
        recipientAlice.percentAllocation = 60_00_00;

        DiversifierFactory.RecipientParams memory recipientBob = recipientSwapperBob;
        recipientBob.account = users.bob;
        recipientBob.percentAllocation = 40_00_00;

        createDiversifierParams.recipientParams[0] = recipientAlice;
        createDiversifierParams.recipientParams[1] = recipientBob;

        // sort createSplit params
        address[] memory accounts = new address[](2);
        (accounts[0], accounts[1]) = (users.alice, users.bob);
        uint32[] memory percentAllocations = new uint32[](2);
        (percentAllocations[0], percentAllocations[1]) = (60_00_00, 40_00_00);
        if (users.alice > users.bob) {
            (accounts[0], accounts[1]) = (users.bob, users.alice);
            (percentAllocations[0], percentAllocations[1]) = (percentAllocations[1], percentAllocations[0]);
        }

        vm.expectCall({
            callee: address(splitMain),
            msgValue: 0 ether,
            data: abi.encodeCall(ISplitMain.createSplit, (accounts, percentAllocations, 0, expectedPassThroughWallet))
        });
        diversifierFactory.createDiversifier(createDiversifierParams);
    }

    /// @dev it should create a split with diversifier controller
    function testFork_createDiversifier_createsSplit_withDiversifierController() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        address expectedSplit = _predictNextAddressFrom(address(splitMain));

        address diversifier = diversifierFactory.createDiversifier(createDiversifierParams);
        assertEq(splitMain.getController(expectedSplit), diversifier);
    }

    // TODO: technically this is already covered in the og create split check?
    /// @dev it should create a split with recipients from args

    /// -----------------------------------------------------------------------
    /// tests - basic - _parseRecipientParams
    /// -----------------------------------------------------------------------

    /* function testFork_parseRecipientParams() public { */
    /*     DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams(); */

    /*     address[] memory accounts = new address[](2); */
    /*     // new swapper address is mock'd to return users.bob */
    /*     (accounts[0], accounts[1]) = (createDiversifierParams.recipientParams[0].account, users.bob); */
    /*     uint32[] memory percentAllocations = new uint32[](2); */
    /*     (percentAllocations[0], percentAllocations[1]) = ( */
    /*         createDiversifierParams.recipientParams[0].percentAllocation, */
    /*         createDiversifierParams.recipientParams[1].percentAllocation */
    /*     ); */

    /*     vm.mockCall({ */
    /*         callee: address(swapperFactory), */
    /*         msgValue: 0, */
    /*         data: abi.encodeCall(SwapperFactory.createSwapper, (swapperInit)), */
    /*         returnData: abi.encode(users.bob) */
    /*     }); */
    /*     (address[] memory parsedAccounts, uint32[] memory parsedPercentAllocations) = */
    /*         diversifierFactory.exposed_parseRecipientParams(recipientParams); */

    /*     assertEq(parsedAccounts, accounts); */
    /*     assertEq(parsedPercentAllocations, percentAllocations); */
    /* } */

    /// -----------------------------------------------------------------------
    /// tests - fuzz
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// tests - fuzz - _parseRecipientParams
    /// -----------------------------------------------------------------------

    /* function testForkFuzz_parseRecipientParams(DiversifierFactory.RecipientParams[] memory recipientParams_) public { */
    /*     uint256 length = recipientParams_.length; */
    /*     address[] memory accounts = new address[](length); */
    /*     uint32[] memory percentAllocations = new uint32[](length); */
    /*     // new swapper addresses are mock'd to return their index */
    /*     for (uint256 i; i < length; i++) { */
    /*         DiversifierFactory.RecipientParams memory recipient = recipientParams_[i]; */
    /*         percentAllocations[i] = recipient.percentAllocation; */
    /*         if (recipient.account != ADDRESS_ZERO) { */
    /*             accounts[i] = recipient.account; */
    /*         } else { */
    /*             address mockSwapper = address(bytes20(keccak256(abi.encode(recipient.createSwapper)))); */
    /*             accounts[i] = mockSwapper; */
    /*             vm.mockCall({ */
    /*                 callee: address(swapperFactory), */
    /*                 msgValue: 0, */
    /*                 data: abi.encodeCall(SwapperFactory.createSwapper, (recipient.createSwapper)), */
    /*                 returnData: abi.encode(mockSwapper) */
    /*             }); */
    /*         } */
    /*     } */

    /*     (address[] memory parsedAccounts, uint32[] memory parsedPercentAllocations) = */
    /*         diversifierFactory.exposed_parseRecipientParams(recipientParams_); */

    /*     assertEq(parsedAccounts, accounts); */
    /*     assertEq(parsedPercentAllocations, percentAllocations); */
    /* } */

    /// -----------------------------------------------------------------------
    /// internal
    /// -----------------------------------------------------------------------

    /// @dev can't be init'd in setUp & saved to storage bc of nested dynamic array solc error
    /// UnimplementedFeatureError: Copying of type struct DiversifierFactory.RecipientParams memory[] memory to storage not yet supported.
    function _createDiversifierParams() internal view returns (DiversifierFactory.CreateDiversifierParams memory) {
        return DiversifierFactory.CreateDiversifierParams({
            owner: users.alice,
            paused: false,
            oracleParams: oracleParams,
            recipientParams: recipientParams
        });
    }
}

contract DiversifierFactoryHarness is DiversifierFactory {
    constructor(
        ISplitMain splitMain_,
        SwapperFactory swapperFactory_,
        PassThroughWalletFactory passThroughWalletFactory_
    ) DiversifierFactory(splitMain_, swapperFactory_, passThroughWalletFactory_) {}

    function exposed_parseRecipientParams(
        address diversifier_,
        OracleImpl oracle_,
        DiversifierFactory.RecipientParams[] calldata recipientParams_
    ) external returns (address[] memory, uint32[] memory) {
        return _parseRecipientParams(diversifier_, oracle_, recipientParams_);
    }

    function exposed_parseOracleParams(address diversifier_, OracleParams calldata oracleParams_)
        external
        returns (OracleImpl)
    {
        return _parseOracleParams(diversifier_, oracleParams_);
    }
}
