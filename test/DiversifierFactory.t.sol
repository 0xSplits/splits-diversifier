// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "splits-tests/Base.t.sol";

import {CreateOracleParams, OracleParams} from "splits-oracle/peripherals/OracleParams.sol";
import {IOracle} from "splits-oracle/interfaces/IOracle.sol";
import {IOracleFactory} from "splits-oracle/interfaces/IOracleFactory.sol";
import {ISplitMain} from "splits-utils/interfaces/ISplitMain.sol";
import {LibRecipients} from "splits-utils/LibRecipients.sol";
import {OracleImpl} from "splits-oracle/OracleImpl.sol";
import {OwnableImpl} from "splits-utils/OwnableImpl.sol";
import {PassThroughWalletImpl} from "splits-pass-through-wallet/PassThroughWalletImpl.sol";
import {PassThroughWalletFactory} from "splits-pass-through-wallet/PassThroughWalletFactory.sol";
import {SwapperImpl} from "splits-swapper/SwapperImpl.sol";
import {SwapperFactory} from "splits-swapper/SwapperFactory.sol";
import {UniV3OracleImpl} from "splits-oracle/UniV3OracleImpl.sol";
import {UniV3OracleFactory} from "splits-oracle/UniV3OracleFactory.sol";
import {WalletImpl} from "splits-utils/WalletImpl.sol";

import {DiversifierFactory} from "../src/DiversifierFactory.sol";

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
    OracleImpl oracle;

    function setUp() public virtual override {
        super.setUp();

        vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);

        splitMain = ISplitMain(SPLIT_MAIN);
        oracleFactory = new UniV3OracleFactory({
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

        oracle = oracleFactory.createUniV3Oracle(initOracleParams);
        oracleParams.oracle = oracle;
    }

    function _createDiversifierParams() internal view returns (DiversifierFactory.CreateDiversifierParams memory) {
        return DiversifierFactory.CreateDiversifierParams({
            owner: users.alice,
            paused: false,
            oracleParams: oracleParams,
            recipientParams: recipientParams
        });
    }

    /// -----------------------------------------------------------------------
    /// createDiversifier
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
    // it should create a split with the correct controller & recipients
    //  with diversifier controller

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

        uint64 preCallOracleFactoryNonce = vm.getNonce(address(oracleFactory));
        diversifierFactory.createDiversifier(createDiversifierParams);
        uint64 postCallOracleFactoryNonce = vm.getNonce(address(oracleFactory));
        assertEq(preCallOracleFactoryNonce, postCallOracleFactoryNonce);
    }

    /// @dev it shouldn't create an oracle if given one
    function testFailFork_createDiversifier_notCreateOracleWhenProvidedOne() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        vm.expectCall({callee: address(oracleFactory), data: ""});
        diversifierFactory.createDiversifier(createDiversifierParams);
    }

    /// @dev it should create an oracle if not given one
    function testFork_createDiversifier_createsOracleWhenNotProvidedOne() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        createDiversifierParams.oracleParams.oracle = IOracle(ADDRESS_ZERO);
        vm.expectCall({
            callee: address(oracleFactory),
            msgValue: 0 ether,
            data: abi.encodeCall(IOracleFactory.createOracle, abi.encode(initOracleParams))
        });
        diversifierFactory.createDiversifier(createDiversifierParams);
    }

    /// @dev it should create swappers
    function testFork_createDiversifier_createsSwappers() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        address expectedPassThroughWallet = _predictNextAddressFrom(address(passThroughWalletFactory));
        OracleParams memory swapperOracleParams;
        swapperOracleParams.oracle = oracle;

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
                                oracleParams: swapperOracleParams,
                                defaultScaledOfferFactor: rp.createSwapperParams.defaultScaledOfferFactor,
                                pairScaledOfferFactors: rp.createSwapperParams.pairScaledOfferFactors
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

        address[] memory expectedSwappers = _predictNextAddressesFrom(address(swapperFactory), 2);

        diversifierFactory.createDiversifier(createDiversifierParams);
        for (uint256 i; i < expectedSwappers.length; i++) {
            assertEq(address(SwapperImpl(expectedSwappers[i]).oracle()), address(oracle));
        }
    }

    /// @dev it should create swappers with new oracle from factory args, if oracle not provided
    function testFork_createDiversifier_createsSwappers_withNewOracle() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();
        createDiversifierParams.oracleParams.oracle = IOracle(ADDRESS_ZERO);

        address expectedOracle = _predictNextAddressFrom(address(oracleFactory));
        address[] memory expectedSwappers = _predictNextAddressesFrom(address(swapperFactory), 2);

        diversifierFactory.createDiversifier(createDiversifierParams);
        for (uint256 i; i < expectedSwappers.length; i++) {
            assertEq(address(SwapperImpl(expectedSwappers[i]).oracle()), expectedOracle);
        }
    }

    /// @dev it should create a split with the correct controller & recipients
    function testFork_createDiversifier_createsSplit_withCorrectControllerAndRecipients() public {
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

    /// -----------------------------------------------------------------------
    /// _parseOracleParams
    /// -----------------------------------------------------------------------

    function testFork_parseOracleParams_returnsExistingOracleIfProvided() public {
        oracleParams.oracle = IOracle(users.alice);
        oracle = diversifierFactory.exposed_parseOracleParams(users.bob, oracleParams);
        assertEq(address(oracle), users.alice);
    }

    function testForkFuzz_parseOracleParams_returnsExistingOracleIfProvided(address oracle_) public {
        vm.assume(oracle_ != ADDRESS_ZERO);
        oracleParams.oracle = IOracle(oracle_);
        oracle = diversifierFactory.exposed_parseOracleParams(users.bob, oracleParams);
        assertEq(address(oracle), oracle_);
    }

    function testFork_parseOracleParams_createsNewOracleIfNotProvided() public {
        oracleParams.oracle = IOracle(ADDRESS_ZERO);
        address expectedOracle = _predictNextAddressFrom(address(oracleFactory));

        vm.expectCall({
            callee: address(oracleFactory),
            data: abi.encodeCall(IOracleFactory.createOracle, (abi.encode(initOracleParams)))
        });
        oracle = diversifierFactory.exposed_parseOracleParams(users.bob, oracleParams);
        assertEq(address(oracle), expectedOracle);
        assertEq(OracleImpl(address(oracle)).owner(), users.alice);
    }

    function testForkFuzz_parseOracleParams_createsNewOracleIfNotProvided(
        address diversifier_,
        CreateOracleParams calldata createOracleParams_
    ) public {
        vm.assume(address(vm) != address(createOracleParams_.factory));

        oracleParams.oracle = IOracle(ADDRESS_ZERO);
        oracleParams.createOracleParams = createOracleParams_;
        vm.mockCall(
            address(createOracleParams_.factory),
            0,
            abi.encodeCall(IOracleFactory.createOracle, (createOracleParams_.data)),
            abi.encode(users.alice)
        );
        vm.mockCall(users.alice, 0, abi.encodeCall(OwnableImpl.owner, ()), abi.encode(users.bob));
        oracle = diversifierFactory.exposed_parseOracleParams(diversifier_, oracleParams);
        assertEq(address(oracle), users.alice);
    }

    function testFork_parseOracleParams_createsNewOracleIfNotProvided_andTransfersOwnership() public {
        oracleParams.oracle = IOracle(ADDRESS_ZERO);
        initOracleParams.owner = address(diversifierFactory);
        oracleParams.createOracleParams.data = abi.encode(initOracleParams);
        oracle = diversifierFactory.exposed_parseOracleParams(users.bob, oracleParams);
        assertEq(OracleImpl(address(oracle)).owner(), users.bob);
    }

    /// -----------------------------------------------------------------------
    /// _parseRecipientParams
    /// -----------------------------------------------------------------------

    function testFork_parseRecipientParams() public {
        uint256 length = recipientParams.length;
        uint64 nonce = vm.getNonce(address(swapperFactory));
        address[] memory accounts = new address[](length);
        uint32[] memory percentAllocations = new uint32[](length);
        for (uint256 i; i < length; i++) {
            accounts[i] = recipientParams[i].account._isNotEmpty()
                ? recipientParams[i].account
                : _predictNextAddressFrom(address(swapperFactory), nonce++);
            percentAllocations[i] = recipientParams[i].percentAllocation;
        }
        LibRecipients._sortRecipientsInPlace(accounts, percentAllocations);

        (address[] memory parsedAccounts, uint32[] memory parsedPercentAllocations) =
            diversifierFactory.exposed_parseRecipientParams(users.alice, OracleImpl(users.bob), recipientParams);

        assertEq(parsedAccounts, accounts);
        assertEq(parsedPercentAllocations, percentAllocations);
    }

    function testForkFuzz_parseRecipientParams(DiversifierFactory.RecipientParams[] calldata recipientParams_) public {
        uint256 length = recipientParams_.length;
        uint64 nonce = vm.getNonce(address(swapperFactory));
        address[] memory accounts = new address[](length);
        uint32[] memory percentAllocations = new uint32[](length);
        for (uint256 i; i < length; i++) {
            accounts[i] = recipientParams_[i].account._isNotEmpty()
                ? recipientParams_[i].account
                : _predictNextAddressFrom(address(swapperFactory), nonce++);
            percentAllocations[i] = recipientParams_[i].percentAllocation;
        }
        LibRecipients._sortRecipientsInPlace(accounts, percentAllocations);

        (address[] memory parsedAccounts, uint32[] memory parsedPercentAllocations) =
            diversifierFactory.exposed_parseRecipientParams(users.alice, OracleImpl(users.bob), recipientParams_);

        assertEq(parsedAccounts, accounts);
        assertEq(parsedPercentAllocations, percentAllocations);
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
