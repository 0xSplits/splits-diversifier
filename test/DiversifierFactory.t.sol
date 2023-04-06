// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {BaseTest} from "splits-tests/base.t.sol";

import {DiversifierFactory} from "src/DiversifierFactory.sol";

import {CreateOracleParams, IOracle, IOracleFactory} from "splits-oracle/interfaces/IOracleFactory.sol";
import {ISplitMain} from "splits-utils/interfaces/ISplitMain.sol";
import {IUniswapV3Factory, UniV3OracleFactory, UniV3OracleImpl} from "splits-oracle/UniV3OracleFactory.sol";
import {
    PassThroughWalletFactory, PassThroughWalletImpl
} from "splits-pass-through-wallet/PassThroughWalletFactory.sol";
import {SwapperFactory, SwapperImpl} from "splits-swapper/SwapperFactory.sol";
import {WalletImpl} from "splits-utils/WalletImpl.sol";

// TODO: ISplitMain conflicts w BaseTest ?
// TODO: add fuzzing

contract DiversifierFactoryTest is BaseTest {
    event CreateDiversifier(address indexed diversifier);
    event CreateSwapper(SwapperImpl indexed swapper, SwapperImpl.InitParams params);

    IUniswapV3Factory constant UNISWAP_V3_FACTORY = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    ISplitMain splitMain;
    UniV3OracleFactory oracleFactory;
    SwapperFactory swapperFactory;
    PassThroughWalletFactory passThroughWalletFactory;

    DiversifierFactoryHarness diversifierFactory;

    DiversifierFactory.Recipient[] recipients;
    DiversifierFactory.Recipient recipient_isSwapper;
    DiversifierFactory.Recipient recipient_isNotSwapper;

    uint32[] initPercentAllocations;

    CreateOracleParams createOracleParams;
    SwapperImpl.InitParams swapperInit;

    function setUp() public virtual override {
        super.setUp();

        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(MAINNET_RPC_URL, BLOCK_NUMBER);

        splitMain = ISplitMain(address(SPLIT_MAIN));
        oracleFactory = new UniV3OracleFactory({
            uniswapV3Factory_: UNISWAP_V3_FACTORY,
            weth9_: WETH9
        });
        swapperFactory = new SwapperFactory();
        passThroughWalletFactory = new PassThroughWalletFactory();

        diversifierFactory = new DiversifierFactoryHarness({
            splitMain_: splitMain,
            swapperFactory_: swapperFactory,
            passThroughWalletFactory_: passThroughWalletFactory
        });

        swapperInit = SwapperImpl.InitParams({
            owner: users.bob,
            paused: false,
            beneficiary: ZERO_ADDRESS,
            tokenToBeneficiary: ZERO_ADDRESS,
            oracle: IOracle(ZERO_ADDRESS)
            });
        recipient_isSwapper = DiversifierFactory.Recipient({
            account: ZERO_ADDRESS,
            createSwapper: swapperInit
        });
        recipient_isNotSwapper = DiversifierFactory.Recipient({
            account: users.alice,
            createSwapper: SwapperImpl.InitParams({
                owner: ZERO_ADDRESS,
                paused: false,
                beneficiary: ZERO_ADDRESS,
                tokenToBeneficiary: ZERO_ADDRESS,
                oracle: IOracle(ZERO_ADDRESS)
            })
        });

        recipients.push(recipient_isSwapper);
        recipients.push(recipient_isNotSwapper);

        initPercentAllocations.push(PERCENTAGE_SCALE / 2); // = 500_000
        initPercentAllocations.push(PERCENTAGE_SCALE / 2); // = 500_000

        createOracleParams = CreateOracleParams({
            factory: IOracleFactory(address(oracleFactory)),
            data: abi.encode(
                UniV3OracleImpl.InitParams({
                    owner: users.alice,
                    defaultFee: 0,
                    defaultPeriod: 0,
                    defaultScaledOfferFactor: 0,
                    pairOverrides: new UniV3OracleImpl.SetPairOverrideParams[](0)
                })
            )
        });
    }

    /// -----------------------------------------------------------------------
    /// tests - basic
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// tests - basic - createDiversifier
    /// -----------------------------------------------------------------------

    function test_createDiversifier_createsPassThroughWallet() public {
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
                        passThrough: ZERO_ADDRESS
                    })
                )
            )
        });
        address diversifier = diversifierFactory.createDiversifier(createDiversifierParams);
        assertTrue(splitMain.getHash(PassThroughWalletImpl(diversifier).$passThrough()) != bytes32(0));
        assertEq(PassThroughWalletImpl(diversifier).$owner(), createDiversifierParams.owner);
    }

    function test_createDiversifier_createsSwappers() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        createDiversifierParams.recipients[0] = DiversifierFactory.Recipient({
            account: ZERO_ADDRESS,
            createSwapper: SwapperImpl.InitParams({
                owner: users.alice,
                paused: false,
                beneficiary: ZERO_ADDRESS,
                tokenToBeneficiary: ZERO_ADDRESS,
                oracle: IOracle(ZERO_ADDRESS)
            })
        });
        createDiversifierParams.recipients[1] = DiversifierFactory.Recipient({
            account: ZERO_ADDRESS,
            createSwapper: SwapperImpl.InitParams({
                owner: users.bob,
                paused: false,
                beneficiary: ZERO_ADDRESS,
                tokenToBeneficiary: ZERO_ADDRESS,
                oracle: IOracle(ZERO_ADDRESS)
            })
        });

        uint256 length = createDiversifierParams.recipients.length;
        for (uint256 i; i < length; i++) {
            vm.expectCall({
                callee: address(swapperFactory),
                msgValue: 0 ether,
                data: abi.encodeCall(SwapperFactory.createSwapper, (createDiversifierParams.recipients[i].createSwapper))
            });
        }
        diversifierFactory.createDiversifier(createDiversifierParams);
    }

    function test_createDiversifier_createsSplit() public {
        DiversifierFactory.CreateDiversifierParams memory createDiversifierParams = _createDiversifierParams();

        // use regular accounts to avoid mocking swapper return addresses
        address[] memory accounts = new address[](2);
        (accounts[0], accounts[1]) = (users.alice < users.bob) ? (users.alice, users.bob) : (users.bob, users.alice);
        for (uint256 i; i < accounts.length; i++) {
            createDiversifierParams.recipients[i] = DiversifierFactory.Recipient({
                account: accounts[i],
                createSwapper: SwapperImpl.InitParams({
                    owner: ZERO_ADDRESS,
                    paused: false,
                    beneficiary: ZERO_ADDRESS,
                    tokenToBeneficiary: ZERO_ADDRESS,
                    oracle: IOracle(ZERO_ADDRESS)
                })
            });
        }

        // create passThroughWallet to capture address & feed into fn via mock
        PassThroughWalletImpl passThroughWallet = passThroughWalletFactory.createPassThroughWallet(
            PassThroughWalletImpl.InitParams({
                owner: address(diversifierFactory),
                paused: createDiversifierParams.paused,
                passThrough: ZERO_ADDRESS
            })
        );

        vm.mockCall({
            callee: address(passThroughWalletFactory),
            msgValue: 0,
            data: abi.encodeCall(
                PassThroughWalletFactory.createPassThroughWallet,
                (
                    PassThroughWalletImpl.InitParams({
                        owner: address(diversifierFactory),
                        paused: createDiversifierParams.paused,
                        passThrough: ZERO_ADDRESS
                    })
                )
            ),
            returnData: abi.encode(passThroughWallet)
        });

        vm.expectCall({
            callee: address(splitMain),
            msgValue: 0 ether,
            data: abi.encodeCall(ISplitMain.createSplit, (accounts, initPercentAllocations, 0, address(passThroughWallet)))
        });
        diversifierFactory.createDiversifier(createDiversifierParams);
    }

    function test_createDiversifier_emitsCreateDiversifier() public {
        // don't check first topic which is new address
        vm.expectEmit({checkTopic1: false, checkTopic2: true, checkTopic3: true, checkData: true});
        emit CreateDiversifier(ZERO_ADDRESS);
        diversifierFactory.createDiversifier(_createDiversifierParams());
    }

    /// -----------------------------------------------------------------------
    /// tests - basic - createOracleAndDiversifier
    /// -----------------------------------------------------------------------

    function test_createOracleAndDiversifier_createsAndUsesOracle() public {
        vm.expectCall({
            callee: address(oracleFactory),
            msgValue: 0 ether,
            data: abi.encodeCall(IOracleFactory.createOracle, (createOracleParams.data))
        });
        diversifierFactory.createOracleAndDiversifier(_createOracleAndDiversifierParams());
    }

    function test_createOracleAndDiversifier_usesOracle() public {
        vm.mockCall({
            callee: address(oracleFactory),
            msgValue: 0,
            data: abi.encodeWithSelector(IOracleFactory.createOracle.selector),
            returnData: abi.encode(users.eve)
        });
        swapperInit.oracle = IOracle(users.eve);

        // don't check first topic which is new address
        vm.expectEmit({checkTopic1: false, checkTopic2: true, checkTopic3: true, checkData: true});
        emit CreateSwapper(SwapperImpl(ZERO_ADDRESS), swapperInit);
        diversifierFactory.createOracleAndDiversifier(_createOracleAndDiversifierParams());
    }

    function test_createOracleAndDiversifier_emitsCreateDiversifier() public {
        // don't check first topic which is new address
        vm.expectEmit({checkTopic1: false, checkTopic2: true, checkTopic3: true, checkData: true});
        emit CreateDiversifier(ZERO_ADDRESS);
        diversifierFactory.createOracleAndDiversifier(_createOracleAndDiversifierParams());
    }

    /// -----------------------------------------------------------------------
    /// tests - basic - _isSwapper
    /// -----------------------------------------------------------------------

    function test_isSwapper() public {
        assertTrue(diversifierFactory.exposed_isSwapper(recipient_isSwapper));
        assertFalse(diversifierFactory.exposed_isSwapper(recipient_isNotSwapper));
    }

    /// -----------------------------------------------------------------------
    /// tests - fuzz
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// tests - fuzz - _isSwapper
    /// -----------------------------------------------------------------------

    function testFuzz_isSwapper(DiversifierFactory.Recipient memory recipient_) public {
        assertEq(recipient_.account == ZERO_ADDRESS, diversifierFactory.exposed_isSwapper(recipient_));
    }

    /// -----------------------------------------------------------------------
    /// internal
    /// -----------------------------------------------------------------------

    /// @dev can't be init'd in setUp & saved to storage bc of nested dynamic array solc error
    /// UnimplementedFeatureError: Copying of type struct DiversifierFactory.Recipient memory[] memory to storage not yet supported.
    function _createDiversifierParams() internal view returns (DiversifierFactory.CreateDiversifierParams memory) {
        return DiversifierFactory.CreateDiversifierParams({
            owner: users.alice,
            paused: false,
            recipients: recipients,
            initPercentAllocations: initPercentAllocations
        });
    }

    function _createOracleAndDiversifierParams()
        internal
        view
        returns (DiversifierFactory.CreateOracleAndDiversifierParams memory)
    {
        return DiversifierFactory.CreateOracleAndDiversifierParams({
            createOracle: createOracleParams,
            createDiversifier: _createDiversifierParams()
        });
    }
}

contract DiversifierFactoryHarness is DiversifierFactory {
    constructor(
        ISplitMain splitMain_,
        SwapperFactory swapperFactory_,
        PassThroughWalletFactory passThroughWalletFactory_
    ) DiversifierFactory(splitMain_, swapperFactory_, passThroughWalletFactory_) {}

    function exposed_isSwapper(DiversifierFactory.Recipient memory recipient_) external pure returns (bool) {
        return _isSwapper(recipient_);
    }
}
