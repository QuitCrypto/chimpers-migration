// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IChimpers {
    function mint(address to, uint256 tokenId) external;
}

/// @title ChimpersMigration
/// @notice Migration contract for moving Chimpers from old to new collection
contract ChimpersMigration is OwnableRoles {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error when claims are closed
    error ClaimsClosed();

    /// @notice Error when batch size exceeds maximum
    error BatchTooLarge();

    /// @notice Error when claims are still open
    error ClaimsNotClosed();

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The old Chimpers contract
    IERC721 public immutable oldChimpers;

    /// @notice The new Chimpers contract
    IChimpers public immutable newChimpers;

    /// @notice Whether claims are closed
    bool public claimsClosed;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param oldChimpers_ The old Chimpers contract address
    /// @param newChimpers_ The new Chimpers contract address
    constructor(address oldChimpers_, address newChimpers_) {
        oldChimpers = IERC721(oldChimpers_);
        newChimpers = IChimpers(newChimpers_);
        _initializeOwner(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                                CLAIM
    //////////////////////////////////////////////////////////////*/

    /// @notice Claims a single token, transferring old and minting new
    /// @param tokenId The token ID to claim
    function claim(uint256 tokenId) external {
        if (claimsClosed) revert ClaimsClosed();
        oldChimpers.transferFrom(msg.sender, address(this), tokenId);
        newChimpers.mint(msg.sender, tokenId);
    }

    /// @notice Claims multiple tokens in a batch
    /// @param tokenIds The token IDs to claim
    function claimBatch(uint256[] calldata tokenIds) external {
        if (claimsClosed) revert ClaimsClosed();
        if (tokenIds.length > 100) revert BatchTooLarge();

        for (uint256 i; i < tokenIds.length; ++i) {
            oldChimpers.transferFrom(msg.sender, address(this), tokenIds[i]);
            newChimpers.mint(msg.sender, tokenIds[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice Closes claims permanently
    function closeClaims() external onlyOwner {
        claimsClosed = true;
    }

    /// @notice Mints unclaimed tokens to treasury after claims are closed
    /// @param tokenIds The token IDs to mint
    /// @param treasury The address to receive the tokens
    function claimUnclaimed(uint256[] calldata tokenIds, address treasury) external onlyOwner {
        if (!claimsClosed) revert ClaimsNotClosed();

        for (uint256 i; i < tokenIds.length; ++i) {
            newChimpers.mint(treasury, tokenIds[i]);
        }
    }
}
