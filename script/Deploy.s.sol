// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script, console} from "forge-std/Script.sol";
import {Chimpers} from "../src/Chimpers.sol";
import {ChimpersMigration} from "../src/ChimpersMigration.sol";

contract DeployScript is Script {
    // Real Chimpers contract on mainnet
    address constant OLD_CHIMPERS = 0x80336Ad7A747236ef41F47ed2C7641828a480BAA;

    // Placeholder royalty values (update before mainnet deploy)
    address constant ROYALTY_RECEIVER = address(0xDEAD);
    uint96 constant ROYALTY_BPS = 500; // 5%

    function run() public {
        vm.startBroadcast();

        // Deploy new Chimpers
        Chimpers chimpers = new Chimpers(
            "Chimpers",
            "CHIMP",
            "https://api.chimpers.xyz/metadata/",
            ROYALTY_RECEIVER,
            ROYALTY_BPS
        );
        console.log("Chimpers deployed at:", address(chimpers));

        // Deploy migration contract
        ChimpersMigration migration = new ChimpersMigration(
            OLD_CHIMPERS,
            address(chimpers)
        );
        console.log("ChimpersMigration deployed at:", address(migration));

        // Set migration contract on new Chimpers
        chimpers.setMigrationContract(address(migration));
        console.log("Migration contract set on Chimpers");

        vm.stopBroadcast();

        // Log summary
        console.log("\n=== Deployment Summary ===");
        console.log("Old Chimpers:", OLD_CHIMPERS);
        console.log("New Chimpers:", address(chimpers));
        console.log("Migration Contract:", address(migration));
        console.log("Royalty Receiver:", ROYALTY_RECEIVER);
        console.log("Royalty BPS:", ROYALTY_BPS);
    }
}
