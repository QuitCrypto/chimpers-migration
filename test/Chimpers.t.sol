// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {Chimpers} from "../src/Chimpers.sol";
import {ERC721} from "solady/tokens/ERC721.sol";

contract ChimpersTest is Test {
    Chimpers public chimpers;

    address owner = address(this);
    address migrationContract = address(0x1234);
    address royaltyReceiver = address(0x5678);
    address alice = address(0xA11CE);

    uint96 royaltyBps = 500; // 5%

    function setUp() public {
        chimpers = new Chimpers(
            "Chimpers",
            "CHIMP",
            "https://api.chimpers.xyz/metadata/",
            royaltyReceiver,
            royaltyBps
        );
        chimpers.setMigrationContract(migrationContract);
    }

    /*//////////////////////////////////////////////////////////////
                          MINT FROM MIGRATION
    //////////////////////////////////////////////////////////////*/

    function test_MintFromMigrationContract() public {
        vm.prank(migrationContract);
        chimpers.mint(alice, 1);

        assertEq(chimpers.ownerOf(1), alice);
        assertEq(chimpers.balanceOf(alice), 1);
    }

    function test_MintFromMigrationContractMultiple() public {
        vm.startPrank(migrationContract);
        chimpers.mint(alice, 1);
        chimpers.mint(alice, 100);
        chimpers.mint(alice, 5555);
        vm.stopPrank();

        assertEq(chimpers.ownerOf(1), alice);
        assertEq(chimpers.ownerOf(100), alice);
        assertEq(chimpers.ownerOf(5555), alice);
        assertEq(chimpers.balanceOf(alice), 3);
    }

    /*//////////////////////////////////////////////////////////////
                      MINT FROM NON-MIGRATION REVERTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_MintFromNonMigration() public {
        vm.expectRevert(Chimpers.OnlyMigrationContract.selector);
        chimpers.mint(alice, 1);
    }

    function test_RevertWhen_MintFromRandomAddress() public {
        vm.prank(alice);
        vm.expectRevert(Chimpers.OnlyMigrationContract.selector);
        chimpers.mint(alice, 1);
    }

    function test_RevertWhen_MintFromOwner() public {
        vm.prank(owner);
        vm.expectRevert(Chimpers.OnlyMigrationContract.selector);
        chimpers.mint(alice, 1);
    }

    /*//////////////////////////////////////////////////////////////
                            ROYALTY INFO
    //////////////////////////////////////////////////////////////*/

    function test_RoyaltyInfo() public {
        vm.prank(migrationContract);
        chimpers.mint(alice, 1);

        (address receiver, uint256 amount) = chimpers.royaltyInfo(1, 10000);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 500); // 5% of 10000
    }

    function test_RoyaltyInfoDifferentSalePrice() public {
        vm.prank(migrationContract);
        chimpers.mint(alice, 1);

        (address receiver, uint256 amount) = chimpers.royaltyInfo(1, 1 ether);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 0.05 ether); // 5% of 1 ether
    }

    function test_SetDefaultRoyalty() public {
        address newReceiver = address(0x9999);
        uint96 newBps = 750; // 7.5%

        chimpers.setDefaultRoyalty(newReceiver, newBps);

        vm.prank(migrationContract);
        chimpers.mint(alice, 1);

        (address receiver, uint256 amount) = chimpers.royaltyInfo(1, 10000);
        assertEq(receiver, newReceiver);
        assertEq(amount, 750);
    }

    /*//////////////////////////////////////////////////////////////
                          BASE URI / TOKEN URI
    //////////////////////////////////////////////////////////////*/

    function test_TokenURI() public {
        vm.prank(migrationContract);
        chimpers.mint(alice, 123);

        assertEq(chimpers.tokenURI(123), "https://api.chimpers.xyz/metadata/123");
    }

    function test_SetBaseURIUpdatesTokenURI() public {
        vm.prank(migrationContract);
        chimpers.mint(alice, 42);

        assertEq(chimpers.tokenURI(42), "https://api.chimpers.xyz/metadata/42");

        chimpers.setBaseURI("ipfs://newbase/");

        assertEq(chimpers.tokenURI(42), "ipfs://newbase/42");
    }

    function test_RevertWhen_TokenURIForNonexistentToken() public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        chimpers.tokenURI(999);
    }

    /*//////////////////////////////////////////////////////////////
                        MIGRATION CONTRACT SETTER
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_SetMigrationContractTwice() public {
        // Migration contract already set in setUp
        vm.expectRevert(Chimpers.MigrationContractAlreadySet.selector);
        chimpers.setMigrationContract(address(0x9999));
    }

    function test_GetMigrationContract() public view {
        assertEq(chimpers.getMigrationContract(), migrationContract);
    }
}
