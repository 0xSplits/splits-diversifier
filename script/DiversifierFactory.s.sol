// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {ISplitMain} from "splits-utils/interfaces/ISplitMain.sol";
import {PassThroughWalletFactory} from "splits-pass-through-wallet/PassThroughWalletFactory.sol";
import {SwapperFactory} from "splits-swapper/SwapperFactory.sol";

import {DiversifierFactory} from "../src/DiversifierFactory.sol";

contract DiversifierFactoryScript is Script {
    using stdJson for string;

    address splitMain;
    address swapperFactory;
    address passThroughWalletFactory;

    function run() public returns (DiversifierFactory df) {
        // https://book.getfoundry.sh/cheatcodes/parse-json
        string memory json = readInput("inputs");

        splitMain = json.readAddress(".splitMain");
        swapperFactory = json.readAddress(".swapperFactory");
        passThroughWalletFactory = json.readAddress(".passThroughWalletFactory");

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privKey);

        df = new DiversifierFactory{salt: keccak256("0xSplits.diversifier.v1")}({
            splitMain_: ISplitMain(splitMain),
            swapperFactory_: SwapperFactory(swapperFactory),
            passThroughWalletFactory_: PassThroughWalletFactory(passThroughWalletFactory)
        });

        vm.stopBroadcast();

        console2.log('DiversifierFactory Deployed:', address(df));
    }

    function readJson(string memory input) internal view returns (bytes memory) {
        return vm.parseJson(readInput(input));
    }

    function readInput(string memory input) internal view returns (string memory) {
        string memory inputDir = string.concat(vm.projectRoot(), "/script/input/");
        string memory chainDir = string.concat(vm.toString(block.chainid), "/");
        string memory file = string.concat(input, ".json");
        return vm.readFile(string.concat(inputDir, chainDir, file));
    }
}
