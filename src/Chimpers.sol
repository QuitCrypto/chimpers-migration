// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "solady/tokens/ERC721.sol";
import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ICreatorToken} from "creator-token-standards/src/interfaces/ICreatorToken.sol";

/// @title Chimpers
/// @notice New Chimpers ERC721 collection for migration
contract Chimpers is ERC721, OwnableRoles, ICreatorToken {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    string private _name;
    string private _symbol;
    string private _baseURI;

    /// @notice Transfer validator contract for ERC721-C royalty enforcement
    address private _transferValidator;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _initializeOwner(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721 METADATA
    //////////////////////////////////////////////////////////////*/

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) revert TokenDoesNotExist();
        return string(abi.encodePacked(_baseURI, LibString.toString(id)));
    }

    /*//////////////////////////////////////////////////////////////
                            ICREATORTOKEN
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICreatorToken
    function getTransferValidator() external view override returns (address validator) {
        return _transferValidator;
    }

    /// @inheritdoc ICreatorToken
    function getTransferValidationFunction() external pure override returns (bytes4 functionSignature, bool isViewFunction) {
        return (bytes4(0), false);
    }

    /// @inheritdoc ICreatorToken
    function setTransferValidator(address validator) external override onlyOwner {
        address oldValidator = _transferValidator;
        _transferValidator = validator;
        emit TransferValidatorUpdated(oldValidator, validator);
    }
}
