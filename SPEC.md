# Chimpers Migration Technical Specification

## Overview

Migration of the Chimpers ERC721 collection from the legacy contract (`0x80336Ad7A747236ef41F47ed2C7641828a480BAA`) to a new ERC721C-compatible contract for royalty enforcement.

---

## 1. Migration Contract

### Architecture

```
┌─────────────────┐      lock()       ┌──────────────────────┐
│  Old Chimpers   │ ───────────────▶  │  ChimpersMigration   │
│  (Legacy ERC721)│                   │  (holds locked NFTs) │
└─────────────────┘                   └──────────────────────┘
                                                │
                                          mint 1:1
                                                │
                                                ▼
                                      ┌──────────────────────┐
                                      │  New Chimpers        │
                                      │  (ERC721C + ERC2981) │
                                      └──────────────────────┘
```

### Contract: `ChimpersMigration.sol`

**Inheritance:**
- `OwnableRoles` (solady) — admin control with transferable ownership

**State:**
```solidity
IERC721 public immutable oldChimpers;
INewChimpers public immutable newChimpers;
bool public claimsClosed;
```

**Functions:**

| Function | Access | Description |
|----------|--------|-------------|
| `claim(uint256 tokenId)` | Public | Lock single token, mint new |
| `claimBatch(uint256[] calldata tokenIds)` | Public | Lock multiple (max 100), mint new |
| `closeClaims()` | Admin | Permanently close claim window |
| `claimUnclaimed(uint256[] calldata tokenIds)` | Admin | After close, mint unclaimed to treasury |

**Flow:**
1. User approves migration contract for old token(s)
2. User calls `claim` or `claimBatch`
3. Contract transfers old token(s) to itself (locked forever)
4. Contract calls `mint(msg.sender, tokenId)` on new contract for each token
5. After admin closes claims, admin can call `claimUnclaimed` with any token IDs not yet claimed

**Validation:**
- `claim`/`claimBatch`: Reverts if `claimsClosed == true`
- `claimBatch`: Reverts if `tokenIds.length > 100`
- `claimUnclaimed`: Reverts if `claimsClosed == false`
- `claimUnclaimed`: Reverts if token already claimed (new contract already minted that ID)

---

### Contract: `Chimpers.sol` (New Collection)

**Inheritance:**
- `ERC721` (solady) - Basic ERC721 contract
- `ICreatorToken` (limitbreak) - "C" extension for 721 or 1155
- `ERC2981` - Royalty definitions onchain
- `OwnableRoles` (solady)

**Constructor Args:**
```solidity
constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    address royaltyReceiver_,
    uint96 royaltyBps_,
    address migrationContract_
)
```

**Key Functions:**

| Function | Access | Description |
|----------|--------|-------------|
| `mint(address to, uint256 tokenId)` | Migration contract only | Mint specific token ID |
| `setBaseURI(string calldata uri)` | Admin | Update metadata URI |
| `setDefaultRoyalty(address receiver, uint96 bps)` | Admin | Update royalty config |

**Constants:**
- `MAX_SUPPLY = 5555`

**Royalty:**
- Configurable via ERC2981 `setDefaultRoyalty`
- Constructor sets initial values

---

## 2. Claim Website

### Stack
- **Framework:** Next.js 14 (App Router)
- **Wallet:** RainbowKit + wagmi + viem
- **Styling:** Tailwind CSS
- **Hosting:** Vercel (or Railway)
- **Domain:** Subdomain of Chimpers site (e.g., `migrate.chimpers.xyz`)

### User Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     CLAIM PAGE                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  [Connect Wallet]                                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  Your Chimpers (Unmigrated):                               │
│                                                             │
│  ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐                  │
│  │ #123  │ │ #456  │ │ #789  │ │ #1011 │  ...             │
│  │  [x]  │ │  [ ]  │ │  [x]  │ │  [ ]  │                  │
│  └───────┘ └───────┘ └───────┘ └───────┘                  │
│                                                             │
│  Selected: 2                                               │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  [Approve & Migrate Selected]                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  Already Migrated: #100, #200, #300                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Technical Implementation

**Data Fetching:**
1. Fetch user's old Chimpers via alchemy `getOwnersForNFT`
2. Display only unmigrated tokens as claimable

**Transaction Flow:**
1. Check approval: `isApprovedForAll(user, migrationContract)` and `getApproved(tokenId)`
2. If not approved: `setApprovalForAll(migrationContract, true)`
3. Call `claimBatch(selectedTokenIds)` (or `claim` for single)
4. Show success state, refresh token list

**Error Handling:**
- Wallet not connected: Show connect prompt
- No unmigrated tokens: Show "All migrated!" or "Nothing to migrate!" message
- Transaction rejected: Show retry option
- Transaction failed: Display error message

---

## 3. TokenWorks Integration

### Current State

**Contract:** `NFTStrategy` at `0x3ca20831EBea5C99AA6E574D83f0A7C733F7e4D0`
**Pattern:** UUPS Proxy (ERC1967)
**Controller:** Chimpers team

**Relevant Storage:**
```solidity
IERC721 public collection;           // Currently points to old Chimpers
mapping(uint256 => uint256) public nftForSale;  // tokenId => price
```

### Required Upgrade

TokenWorks must implement:

1. **Migration Function** (to migrate NFTs held by the strategy)
   ```solidity
   function migrateHeldNFTs(
       uint256[] calldata tokenIds
   ) external onlyOwner {
       // Approve migration contract
       oldCollection.setApprovalForAll(migrationContract, true);
       // Call claim batch
       IChimpersMigration(migrationContract).claimBatch(tokenIds);
       // Revoke approval
       oldCollection.setApprovalForAll(migrationContract, false);
   }
   ```

### Migration Sequence

```
1. Deploy ChimpersV2 + ChimpersMigration
2. TokenWorks upgrades NFTStrategy with new functions
3. TokenWorks calls migrateHeldNFTs() to claim their held tokens
4. TokenWorks resumes normal operations with new collection
```

---

## 4. Testing Strategy

**Environment:** Foundry with mainnet fork

**Test Categories:**

1. **Unit Tests**
   - Claim single token
   - Claim batch (1, 50, 100, 101 tokens)
   - Claim already-claimed token (should fail)
   - Close claims
   - Claim unclaimed after close
   - Claim unclaimed before close (should fail)
   - Admin role transfers

2. **Integration Tests (Fork)**
   - Claim real token IDs from mainnet state
   - Verify metadata URI resolves correctly
   - Verify royalty info returns expected values

3. **TokenWorks Simulation**
   - Simulate NFTStrategy holding tokens
   - Test migration flow from strategy's perspective

---

## 5. Deployment Sequence

```
1. Deploy ChimpersV2
   - Constructor: name, symbol, baseURI, royaltyReceiver, royaltyBps, migrationContract (address(0) temporarily)

2. Deploy ChimpersMigration
   - Constructor: oldChimpers, newChimpers addresses

3. Set migration contract on ChimpersV2
   - Call setMigrationContract(migrationContractAddress)

4. Verify contracts on Etherscan

5. Deploy claim website to Vercel

6. Configure subdomain DNS
```

---

## 6. Contract Addresses

| Contract | Address |
|----------|---------|
| Old Chimpers | `0x80336Ad7A747236ef41F47ed2C7641828a480BAA` |
| TokenWorks (NFTStrategy) | `0x3ca20831EBea5C99AA6E574D83f0A7C733F7e4D0` |
| New Chimpers | TBD |
| Migration Contract | TBD |

---

