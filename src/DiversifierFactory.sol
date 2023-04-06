// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {CreateOracleParams, IOracle, IOracleFactory} from "splits-oracle/interfaces/IOracleFactory.sol";
import {ISplitMain} from "splits-utils/interfaces/ISplitMain.sol";
import {LibSort} from "solady/utils/LibSort.sol";
import {
    PassThroughWalletFactory, PassThroughWalletImpl
} from "splits-pass-through-wallet/PassThroughWalletFactory.sol";
import {SwapperFactory, SwapperImpl} from "splits-swapper/SwapperFactory.sol";
import {WalletImpl} from "splits-utils/WalletImpl.sol";

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
    /// libraries
    /// -----------------------------------------------------------------------

    using LibSort for uint256[];

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
        uint32[] initPercentAllocations;
    }

    struct Recipient {
        address account;
        SwapperImpl.InitParams createSwapper;
    }

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// storage - constants & immutables
    /// -----------------------------------------------------------------------

    address internal constant ZERO_ADDRESS = address(0);
    uint256 internal constant UINT96_BITS = 96;

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

    // TODO: break into shorter internal fns for fuzzing etc ?

    function _createDiversifier(CreateDiversifierParams memory params_) internal returns (address diversifier) {
        // create pass-through wallet w self as owner
        PassThroughWalletImpl passThroughWallet = passThroughWalletFactory.createPassThroughWallet(
            PassThroughWalletImpl.InitParams({owner: address(this), paused: params_.paused, passThrough: ZERO_ADDRESS})
        );

        // create swappers & prep array to be in-place sorted for createSplit
        // by packing initPercentAllocations into the right-most 12 bytes
        uint256 length = params_.recipients.length;
        uint256[] memory packedRecipients = new uint256[](length);
        for (uint256 i; i < length;) {
            Recipient memory recipient = params_.recipients[i];
            address account = _isSwapper(recipient)
                ? address(swapperFactory.createSwapper(recipient.createSwapper))
                : recipient.account;
            packedRecipients[i] = (uint256(uint160(account)) << UINT96_BITS) | params_.initPercentAllocations[i];

            unchecked {
                ++i;
            }
        }

        // sort packedRecipients (recipient|allocation) & unpack
        packedRecipients.sort();
        address[] memory sortedAccounts;
        /// @solidity memory-safe-assembly
        assembly {
            sortedAccounts := packedRecipients // re-use memory
        }
        uint32[] memory sortedInitPercentAllocations = new uint32[](length);
        for (uint256 i; i < length;) {
            uint256 packedRecipient = packedRecipients[i];
            sortedInitPercentAllocations[i] = uint32(packedRecipient);
            sortedAccounts[i] = address(uint160(packedRecipient >> UINT96_BITS));

            unchecked {
                ++i;
            }
        }

        // create split w pass-through wallet as controller
        address passThroughSplit = payable(
            splitMain.createSplit({
                accounts: sortedAccounts,
                percentAllocations: sortedInitPercentAllocations,
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

    function _isSwapper(Recipient memory recipient_) internal pure returns (bool) {
        return recipient_.account == ZERO_ADDRESS;
    }
}
