// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {Chimpers} from "../src/Chimpers.sol";
import {ChimpersMigration} from "../src/ChimpersMigration.sol";

/// @dev Mock old Chimpers for testing
contract MockOldChimpers is ERC721 {
    function name() public pure override returns (string memory) {
        return "Old Chimpers";
    }

    function symbol() public pure override returns (string memory) {
        return "OLDCHIMP";
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract ChimpersMigrationTest is Test {
    MockOldChimpers public oldChimpers;
    Chimpers public newChimpers;
    ChimpersMigration public migration;

    address owner = address(this);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address treasury = address(0x77EA5);

    function setUp() public {
        // Deploy old Chimpers mock
        oldChimpers = new MockOldChimpers();

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
            address(oldChimpers),
            address(newChimpers)
        );

        // Set migration contract on new Chimpers
        newChimpers.setMigrationContract(address(migration));
    }

    /*//////////////////////////////////////////////////////////////
                          CLAIM SINGLE TOKEN
    //////////////////////////////////////////////////////////////*/

    function test_ClaimTransfersOldAndMintsNew() public {
        // Mint old token to alice
        oldChimpers.mint(alice, 1);
        assertEq(oldChimpers.ownerOf(1), alice);

        // Alice approves migration contract
        vm.prank(alice);
        oldChimpers.approve(address(migration), 1);

        // Alice claims
        vm.prank(alice);
        migration.claim(1);

        // Old token now owned by migration contract
        assertEq(oldChimpers.ownerOf(1), address(migration));
        // New token owned by alice
        assertEq(newChimpers.ownerOf(1), alice);
    }

    function test_ClaimMultipleTokensSequentially() public {
        // Mint multiple old tokens to alice
        oldChimpers.mint(alice, 10);
        oldChimpers.mint(alice, 20);
        oldChimpers.mint(alice, 30);

        // Alice approves all
        vm.startPrank(alice);
        oldChimpers.setApprovalForAll(address(migration), true);

        migration.claim(10);
        migration.claim(20);
        migration.claim(30);
        vm.stopPrank();

        // Verify migrations
        assertEq(oldChimpers.ownerOf(10), address(migration));
        assertEq(oldChimpers.ownerOf(20), address(migration));
        assertEq(oldChimpers.ownerOf(30), address(migration));
        assertEq(newChimpers.ownerOf(10), alice);
        assertEq(newChimpers.ownerOf(20), alice);
        assertEq(newChimpers.ownerOf(30), alice);
    }

    /*//////////////////////////////////////////////////////////////
                          CLAIM BATCH
    //////////////////////////////////////////////////////////////*/

    function test_ClaimBatchMultipleTokens() public {
        // Mint tokens to alice
        oldChimpers.mint(alice, 1);
        oldChimpers.mint(alice, 2);
        oldChimpers.mint(alice, 3);

        // Alice approves all
        vm.prank(alice);
        oldChimpers.setApprovalForAll(address(migration), true);

        // Alice claims batch
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.prank(alice);
        migration.claimBatch(tokenIds);

        // Verify all migrated
        assertEq(oldChimpers.ownerOf(1), address(migration));
        assertEq(oldChimpers.ownerOf(2), address(migration));
        assertEq(oldChimpers.ownerOf(3), address(migration));
        assertEq(newChimpers.ownerOf(1), alice);
        assertEq(newChimpers.ownerOf(2), alice);
        assertEq(newChimpers.ownerOf(3), alice);
    }

    function test_ClaimBatchExactly100Tokens() public {
        // Mint 100 tokens to alice
        for (uint256 i = 1; i <= 100; ++i) {
            oldChimpers.mint(alice, i);
        }

        // Alice approves all
        vm.prank(alice);
        oldChimpers.setApprovalForAll(address(migration), true);

        // Build batch of 100
        uint256[] memory tokenIds = new uint256[](100);
        for (uint256 i; i < 100; ++i) {
            tokenIds[i] = i + 1;
        }

        // Alice claims batch of exactly 100 (should succeed)
        vm.prank(alice);
        migration.claimBatch(tokenIds);

        // Verify all migrated
        assertEq(newChimpers.ownerOf(1), alice);
        assertEq(newChimpers.ownerOf(100), alice);
    }

    function test_RevertWhen_ClaimBatchOver100Tokens() public {
        // Build batch of 101
        uint256[] memory tokenIds = new uint256[](101);
        for (uint256 i; i < 101; ++i) {
            tokenIds[i] = i + 1;
        }

        vm.prank(alice);
        vm.expectRevert(ChimpersMigration.BatchTooLarge.selector);
        migration.claimBatch(tokenIds);
    }

    /*//////////////////////////////////////////////////////////////
                          CLOSE CLAIMS
    //////////////////////////////////////////////////////////////*/

    function test_CloseClaimsBlocksFurtherClaims() public {
        // Mint token to alice
        oldChimpers.mint(alice, 1);

        // Alice approves
        vm.prank(alice);
        oldChimpers.approve(address(migration), 1);

        // Owner closes claims
        migration.closeClaims();
        assertTrue(migration.claimsClosed());

        // Alice tries to claim
        vm.prank(alice);
        vm.expectRevert(ChimpersMigration.ClaimsClosed.selector);
        migration.claim(1);
    }

    function test_CloseClaimsBlocksBatchClaims() public {
        // Mint token to alice
        oldChimpers.mint(alice, 1);

        // Alice approves
        vm.prank(alice);
        oldChimpers.setApprovalForAll(address(migration), true);

        // Owner closes claims
        migration.closeClaims();

        // Alice tries to batch claim
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(alice);
        vm.expectRevert(ChimpersMigration.ClaimsClosed.selector);
        migration.claimBatch(tokenIds);
    }

    function test_ClaimSucceedsBeforeClose() public {
        // Mint token to alice
        oldChimpers.mint(alice, 1);

        // Alice approves and claims before close
        vm.startPrank(alice);
        oldChimpers.approve(address(migration), 1);
        migration.claim(1);
        vm.stopPrank();

        assertEq(newChimpers.ownerOf(1), alice);

        // Now close
        migration.closeClaims();

        // Alice can't claim more
        oldChimpers.mint(alice, 2);
        vm.startPrank(alice);
        oldChimpers.approve(address(migration), 2);
        vm.expectRevert(ChimpersMigration.ClaimsClosed.selector);
        migration.claim(2);
        vm.stopPrank();
    }
}
