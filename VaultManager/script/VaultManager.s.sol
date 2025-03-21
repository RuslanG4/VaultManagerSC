// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import { VaultManager } from "../src/VaultManager.sol";

contract VaultManagerScript is Script {
    VaultManager public vaultManager;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        vaultManager = new VaultManager();

        vm.stopBroadcast();
    }
}
