// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {CreateOracleParams, IOracle, IOracleFactory} from "splits-oracle/interfaces/IOracleFactory.sol";
import {ISplitMain} from "splits-utils/interfaces/ISplitMain.sol";
import {
    PassThroughWalletFactory, PassThroughWalletImpl
} from "splits-pass-through-wallet/PassThroughWalletFactory.sol";
import {SwapperFactory, SwapperImpl} from "splits-swapper/SwapperFactory.sol";
import {WalletImpl} from "splits-utils/WalletImpl.sol";
import {_sortRecipients} from "splits-utils/recipients.sol";

// TODO: review comments

/// @title Diversifier Factory
/// @author 0xSplits
/// @notice Factory for creating Diversifiers.
/// A Diversifier is a PassThroughWallet on top of a Split on top of one or
/// more Swappers. With this structure, Diversifiers trustlessly & automatically
/// diversify onchain revenue.
/// Please be aware, owner has _FULL CONTROL_ of the deployment.
/// @dev This contract uses token = address(0) to refer to ETH.
contract DiversifierFactory {
    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    event CreateDiversifier(address indexed diversifier);

    /// -----------------------------------------------------------------------
    /// structs
    /// -----------------------------------------------------------------------

    struct CreateOracleAndDiversifierParams {
        CreateOracleParams createOracle;
        CreateDiversifierParams createDiversifier;
    }

    struct CreateDiversifierParams {
        address owner;
        bool paused;
        Recipient[] recipients;
    }

    struct Recipient {
        address account;
        SwapperImpl.InitParams createSwapper;
        uint32 percentAllocation;
    }

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// storage - constants & immutables
    /// -----------------------------------------------------------------------

    address internal constant ZERO_ADDRESS = address(0);

    ISplitMain public immutable splitMain;
    SwapperFactory public immutable swapperFactory;
    PassThroughWalletFactory public immutable passThroughWalletFactory;

    /// -----------------------------------------------------------------------
    /// constructor
    /// -----------------------------------------------------------------------

    constructor(
        ISplitMain splitMain_,
        SwapperFactory swapperFactory_,
        PassThroughWalletFactory passThroughWalletFactory_
    ) {
        splitMain = splitMain_;
        swapperFactory = swapperFactory_;
        passThroughWalletFactory = passThroughWalletFactory_;
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    function createDiversifier(CreateDiversifierParams calldata params_) external returns (address) {
        return _createDiversifier(params_);
    }

    /// @dev params_.createDiversifier.recipients[i].createSwapper.oracle are overridden by newly created oracle
    function createOracleAndDiversifier(CreateOracleAndDiversifierParams calldata params_) external returns (address) {
        IOracle oracle = params_.createOracle.factory.createOracle(params_.createOracle.data);

        CreateDiversifierParams memory createDiversifierParams = params_.createDiversifier;
        uint256 length = createDiversifierParams.recipients.length;
        for (uint256 i; i < length;) {
            // if recipient isn't a swapper, oracle will be discarded
            createDiversifierParams.recipients[i].createSwapper.oracle = oracle;

            unchecked {
                ++i;
            }
        }
        return _createDiversifier(createDiversifierParams);
    }

    /// -----------------------------------------------------------------------
    /// functions - private & internal
    /// -----------------------------------------------------------------------

    function _createDiversifier(CreateDiversifierParams memory params_) internal returns (address diversifier) {
        // create pass-through wallet w self as owner & no passThrough
        PassThroughWalletImpl passThroughWallet = passThroughWalletFactory.createPassThroughWallet(
            PassThroughWalletImpl.InitParams({owner: address(this), paused: params_.paused, passThrough: ZERO_ADDRESS})
        );

        (address[] memory accounts, uint32[] memory percentAllocations) = _parseRecipients(params_.recipients);
        (accounts, percentAllocations) = _sortRecipients(accounts, percentAllocations);

        // create split w pass-through wallet as controller
        address passThroughSplit = payable(
            splitMain.createSplit({
                accounts: accounts,
                percentAllocations: percentAllocations,
                distributorFee: 0,
                controller: address(passThroughWallet)
            })
        );

        // set split address as passThrough & transfer ownership from factory
        passThroughWallet.setPassThrough(passThroughSplit);
        passThroughWallet.transferOwnership(params_.owner);

        diversifier = address(passThroughWallet);
        emit CreateDiversifier(diversifier);
    }

    function _parseRecipients(Recipient[] memory recipients_)
        internal
        returns (address[] memory accounts, uint32[] memory percentAllocations)
    {
        uint256 length = recipients_.length;
        accounts = new address[](length);
        percentAllocations = new uint32[](length);
        for (uint256 i; i < length;) {
            Recipient memory recipient = recipients_[i];
            accounts[i] = _isSwapper(recipient)
                ? address(swapperFactory.createSwapper(recipient.createSwapper))
                : recipient.account;
            percentAllocations[i] = recipient.percentAllocation;

            unchecked {
                ++i;
            }
        }
    }

    function _isSwapper(Recipient memory recipient_) internal pure returns (bool) {
        return recipient_.account == ZERO_ADDRESS;
    }
}
