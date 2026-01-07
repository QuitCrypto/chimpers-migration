// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "solady/tokens/ERC721.sol";
import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ICreatorToken} from "creator-token-standards/src/interfaces/ICreatorToken.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import {IERC165} from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";

/// @title Chimpers
/// @notice New Chimpers ERC721 collection for migration
contract Chimpers is ERC721, OwnableRoles, ICreatorToken, IERC2981 {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    string private _name;
    string private _symbol;
    string private _baseURI;

    /// @notice Transfer validator contract for ERC721-C royalty enforcement
    address private _transferValidator;

    /// @notice Default royalty receiver address
    address private _royaltyReceiver;

    /// @notice Default royalty in basis points (e.g., 500 = 5%)
    uint96 private _royaltyBps;

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
        _royaltyReceiver = royaltyReceiver_;
        _royaltyBps = royaltyBps_;
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

    /*//////////////////////////////////////////////////////////////
                                ERC2981
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * _royaltyBps) / 10000;
    }

    /// @notice Sets the default royalty for all tokens
    /// @param receiver The address to receive royalties
    /// @param bps The royalty amount in basis points
    function setDefaultRoyalty(address receiver, uint96 bps) external onlyOwner {
        _royaltyReceiver = receiver;
        _royaltyBps = bps;
    }

    /*//////////////////////////////////////////////////////////////
                            SUPPORTS INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if the contract supports an interface
    /// @param interfaceId The interface identifier
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
