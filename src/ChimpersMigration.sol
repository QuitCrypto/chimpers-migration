// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

/// @title ChimpersMigration
/// @notice Migration contract for moving Chimpers from old to new collection
contract ChimpersMigration is OwnableRoles {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The old Chimpers contract
    IERC721 public immutable oldChimpers;

    /// @notice The new Chimpers contract
    address public immutable newChimpers;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param oldChimpers_ The old Chimpers contract address
    /// @param newChimpers_ The new Chimpers contract address
    constructor(address oldChimpers_, address newChimpers_) {
        oldChimpers = IERC721(oldChimpers_);
        newChimpers = newChimpers_;
        _initializeOwner(msg.sender);
    }
}
