// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Chimpers} from "../src/Chimpers.sol";
import {ChimpersMigration} from "../src/ChimpersMigration.sol";

/// @title ChimpersMigration Fork Tests
/// @notice Tests migration with real mainnet Chimpers contract
contract ChimpersMigrationForkTest is Test {
    // Real Chimpers contract on mainnet
    address constant OLD_CHIMPERS = 0x80336Ad7A747236ef41F47ed2C7641828a480BAA;

    IERC721 public oldChimpers;
    Chimpers public newChimpers;
    ChimpersMigration public migration;

    address public holder1;
    uint256 public holder1TokenId;
    address public holder2;
    uint256[] public holder2TokenIds;

    function setUp() public {
        // Fork mainnet at latest block
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        oldChimpers = IERC721(OLD_CHIMPERS);

        // Find a holder by checking ownership of early tokens
        // Token IDs 1-100 are likely to exist
        for (uint256 i = 1; i <= 100; ++i) {
            try oldChimpers.ownerOf(i) returns (address owner) {
                if (holder1 == address(0)) {
                    holder1 = owner;
                    holder1TokenId = i;
                } else if (owner != holder1 && holder2 == address(0)) {
                    holder2 = owner;
                    holder2TokenIds.push(i);
                } else if (owner == holder2 && holder2TokenIds.length < 3) {
                    holder2TokenIds.push(i);
                }
                if (holder1 != address(0) && holder2TokenIds.length >= 2) break;
            } catch {
                continue;
            }
        }

        // If holder2 doesn't have multiple tokens, find more from same holder
        if (holder2TokenIds.length < 2) {
            for (uint256 i = 101; i <= 500; ++i) {
                try oldChimpers.ownerOf(i) returns (address owner) {
                    if (owner == holder2) {
                        holder2TokenIds.push(i);
                        if (holder2TokenIds.length >= 3) break;
                    } else if (holder2TokenIds.length == 0 || holder2 == address(0)) {
                        holder2 = owner;
                        holder2TokenIds.push(i);
                    }
                } catch {
                    continue;
                }
            }
        }

        require(holder1 != address(0), "Could not find holder1");
        require(holder2TokenIds.length >= 1, "Could not find holder2 with tokens");

        // Deploy new Chimpers
        newChimpers = new Chimpers(
            "Chimpers",
            "CHIMP",
            "https://api.chimpers.xyz/metadata/",
            address(0x5678),
            500
        );

        // Deploy migration contract
        migration = new ChimpersMigration(
            OLD_CHIMPERS,
            address(newChimpers)
        );

        // Set migration contract on new Chimpers
        newChimpers.setMigrationContract(address(migration));
    }

    /*//////////////////////////////////////////////////////////////
                        SINGLE TOKEN CLAIM
    //////////////////////////////////////////////////////////////*/

    function test_Fork_ClaimRealToken() public {
        // Verify holder1 owns the token
        assertEq(oldChimpers.ownerOf(holder1TokenId), holder1);

        // Holder1 approves migration contract
        vm.prank(holder1);
        oldChimpers.approve(address(migration), holder1TokenId);

        // Holder1 claims
        vm.prank(holder1);
        migration.claim(holder1TokenId);

        // Verify migration
        assertEq(oldChimpers.ownerOf(holder1TokenId), address(migration));
        assertEq(newChimpers.ownerOf(holder1TokenId), holder1);
    }

    /*//////////////////////////////////////////////////////////////
                        BATCH CLAIM
    //////////////////////////////////////////////////////////////*/

    function test_Fork_ClaimBatchRealTokens() public {
        // Skip if we don't have multiple tokens from holder2
        if (holder2TokenIds.length < 2) {
            emit log("Skipping batch test - not enough tokens from single holder");
            return;
        }

        // Verify holder2 owns all tokens
        for (uint256 i; i < holder2TokenIds.length; ++i) {
            assertEq(oldChimpers.ownerOf(holder2TokenIds[i]), holder2);
        }

        // Holder2 approves migration contract for all
        vm.prank(holder2);
        oldChimpers.setApprovalForAll(address(migration), true);

        // Holder2 claims batch
        vm.prank(holder2);
        migration.claimBatch(holder2TokenIds);

        // Verify all migrated
        for (uint256 i; i < holder2TokenIds.length; ++i) {
            assertEq(oldChimpers.ownerOf(holder2TokenIds[i]), address(migration));
            assertEq(newChimpers.ownerOf(holder2TokenIds[i]), holder2);
        }
    }
}
