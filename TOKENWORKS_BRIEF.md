# TokenWorks Integration Brief: Chimpers Migration

**To:** TokenWorks Development Team
**From:** Chimpers Migration Team
**Re:** NFTStrategy upgrade for Chimpers ERC721C migration

---

## Summary

Chimpers is migrating to a new ERC721C contract for royalty enforcement. The NFTStrategy contract (`0x3ca20831EBea5C99AA6E574D83f0A7C733F7e4D0`) must be upgraded to:

1. Migrate any Chimpers tokens it currently holds
2. Switch to buying/selling from the new collection

---

## Current State

**Contract:** NFTStrategy (UUPS Proxy)
**Address:** `0x3ca20831EBea5C99AA6E574D83f0A7C733F7e4D0`

**Relevant Storage:**
```solidity
IERC721 public collection;  // Currently: 0x80336Ad7A747236ef41F47ed2C7641828a480BAA (old Chimpers)
mapping(uint256 => uint256) public nftForSale;  // tokenId => salePrice
```

---

## Migration Contracts (We Provide)

| Contract | Address | Notes |
|----------|---------|-------|
| Old Chimpers | `0x80336Ad7A747236ef41F47ed2C7641828a480BAA` | Existing collection |
| New Chimpers | TBD (will provide) | ERC721C collection |
| ChimpersMigration | TBD (will provide) | Lock-and-mint migration |

---

## Required Upgrade Changes
### 1. Add Reference to Legacy Collection
```solidity
address public constant LEGACY_CHIMPERS = 0x80336Ad7A747236ef41F47ed2C7641828a480BAA;
```

### 2. Add Migration Function

Migrate tokens held by NFTStrategy to the new collection:

```solidity
interface IChimpersMigration {
    function claimBatch(uint256[] calldata tokenIds) external;
}

function migrateHeldNFTs(
    uint256[] calldata tokenIds
) external onlyOwner {
    IERC721 old = IERC721(oldCollection);

    // Approve migration contract to take old tokens
    old.setApprovalForAll(migrationContract, true);

    // Migrate tokens (locks old, mints new to this contract)
    IChimpersMigration(migrationContract).claimBatch(tokenIds);

    // Revoke approval
    old.setApprovalForAll(migrationContract, false);
}
```

---

## Migration Sequence

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. Chimpers deploys new contracts                                │
|     - Chimpers.sol
|     - ChimpersMigration.sol
├──────────────────────────────────────────────────────────────────┤
│ 2. TokenWorks deploys upgraded NFTStrategy implementation        │
├──────────────────────────────────────────────────────────────────┤
│ 3. Chimpers team upgrades proxy to new implementation            │
├──────────────────────────────────────────────────────────────────┤
│ 4. TokenWorks/Chimpers calls migrateHeldNFTs()                   │
│    - Pass: array of token IDs                                    │
│    - Result: NFTStrategy now holds new Chimpers tokens           │
├──────────────────────────────────────────────────────────────────┤
│ 7. Resume normal operations                                      │
└──────────────────────────────────────────────────────────────────┘
```

---

## Token ID Preservation

Token IDs are preserved 1:1 in the migration. If NFTStrategy holds old Chimpers #1234, after migration it will hold new Chimpers #1234.

The `nftForSale` mapping uses token IDs as keys. Since IDs are preserved, existing sale entries remain valid (assuming the tokens were migrated).

---

## Testing Recommendations

1. **Fork Test:** Test against mainnet fork to verify migration of actual held tokens
2. **Verify Ownership:** After `migrateHeldNFTs()`, confirm `collection.ownerOf(tokenId) == address(this)` for each migrated token
3. **Buy/Sell Flow:** Test that `buyTargetNFT()` and `sellTargetNFT()` work with new collection

---

## Timeline

- Migration contracts will be deployed within ~1 week
- TokenWorks upgrade can occur any time after contracts are deployed
- No hard deadline, but faster migration = faster return to normal operations

---

## Appendix: Migration Contract Interface

```solidity
interface IChimpersMigration {
    /// @notice Migrate a single token
    /// @param tokenId The token ID to migrate
    function claim(uint256 tokenId) external;

    /// @notice Migrate multiple tokens (max 100)
    /// @param tokenIds Array of token IDs to migrate
    function claimBatch(uint256[] calldata tokenIds) external;
}
```

The migration contract will:
1. Transfer old token from caller to itself (requires prior approval)
2. Mint new token with same ID to caller
3. Old token remains locked in migration contract forever
