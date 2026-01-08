// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "solady/tokens/ERC721.sol";
import {ERC2981} from "solady/tokens/ERC2981.sol";
import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ICreatorToken} from "creator-token-standards/src/interfaces/ICreatorToken.sol";

/// @title Chimpers
/// @notice New Chimpers ERC721 collection for migration
contract Chimpers is ERC721, OwnableRoles, ICreatorToken, ERC2981 {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    string private _name;
    string private _symbol;
    string private _baseURI;

    /// @notice Transfer validator contract for ERC721-C royalty enforcement
    address private _transferValidator;


    /// @notice Migration contract address
    address private _migrationContract;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address royaltyReceiver_,
        uint96 royaltyBps_
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _setDefaultRoyalty(royaltyReceiver_, royaltyBps_);
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

    /// @notice Sets the base URI for token metadata
    /// @param baseURI_ The new base URI
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
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

    /*//////////////////////////////////////////////////////////////
                                ERC2981
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the default royalty for all tokens
    /// @param receiver The address to receive royalties
    /// @param bps The royalty amount in basis points
    function setDefaultRoyalty(address receiver, uint96 bps) external onlyOwner {
        _setDefaultRoyalty(receiver, bps);
    }

    /*//////////////////////////////////////////////////////////////
                              MIGRATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Error when caller is not the migration contract
    error OnlyMigrationContract();

    /// @notice Error when migration contract is already set
    error MigrationContractAlreadySet();

    /// @notice Mints a token to the specified address
    /// @param to The address to mint to
    /// @param tokenId The token ID to mint
    function mint(address to, uint256 tokenId) external {
        if (msg.sender != _migrationContract) revert OnlyMigrationContract();
        _mint(to, tokenId);
    }

    /// @notice Sets the migration contract address (one-time only)
    /// @param migrationContract_ The migration contract address
    function setMigrationContract(address migrationContract_) external onlyOwner {
        if (_migrationContract != address(0)) revert MigrationContractAlreadySet();
        _migrationContract = migrationContract_;
    }

    /// @notice Returns the migration contract address
    function getMigrationContract() external view returns (address) {
        return _migrationContract;
    }

    /*//////////////////////////////////////////////////////////////
                            SUPPORTS INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if the contract supports an interface
    /// @param interfaceId The interface identifier
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || interfaceId == type(ICreatorToken).interfaceId;
    }
}
