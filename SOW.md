# Statement of Work: Chimpers ERC721C Migration

**Prepared for:** Chimpers Team
**Date:** January 2025

---

## Executive Summary

This SOW covers the migration of the Chimpers NFT collection from its current ERC721 contract to a new ERC721C-compatible contract, enabling on-chain royalty enforcement. Deliverables include the migration smart contracts and a claim website for holders.

---

## Scope of Work

### Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | **ChimpersV2 Contract** | New ERC721C collection contract with ERC2981 royalties, matching token IDs 1:1 with original |
| 2 | **ChimpersMigration Contract** | Lock-and-mint migration contract enabling holders to exchange old tokens for new |
| 3 | **Claim Website** | Next.js single-page application for wallet connection and token migration |
| 4 | **Foundry Test Suite** | Comprehensive tests using mainnet fork |
| 5 | **Deployment Scripts** | Foundry scripts for mainnet deployment |

### Features

**Migration Contract:**
- Lock-and-mint mechanism (old tokens locked in contract, new tokens minted)
- Batch claiming (up to 100 tokens per transaction)
- Admin-controlled claim window closure
- Post-closure unclaimed token minting to treasury

**New Collection Contract:**
- ERC721C compatible (royalty enforcement)
- ERC2981 royalty standard (configurable receiver and percentage)
- Same metadata URI as original collection
- 1:1 token ID preservation

**Claim Website:**
- RainbowKit wallet connection (MetaMask, Rabby, WalletConnect)
- Display user's unmigrated Chimpers
- Batch selection and migration
- Transaction status feedback

---

## Out of Scope

| Item | Responsibility |
|------|----------------|
| TokenWorks (NFTStrategy) contract upgrade | TokenWorks team |
| Security audit | Chimpers team decision |
| Marketing/communications | Chimpers team |
| DNS/subdomain configuration | Chimpers team |
| Hosting costs | Chimpers team |

---

## Timeline

**Estimated Duration:** 1 week

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Smart Contracts | 2-3 days | ChimpersV2, ChimpersMigration, tests |
| Claim Website | 2-3 days | Next.js app, deployment |
| Integration & QA | 1-2 days | End-to-end testing, documentation |

---

## Decisions Required from Chimpers Team

### Recommended Decisions

| Decision | Recommendation | Notes |
|----------|----------------|-------|
| **Migration Incentive** | Consider offering a small reward | Encourages faster migration adoption |
| **Security Audit** | Recommended if budget allows | Contract is straightforward but audits reduce risk |
| **Subdomain** | `migrate.chimpers.xyz` or similar | Chimpers team configures DNS |

---

## TokenWorks Coordination

The TokenWorks NFTStrategy contract (`0x3ca20831EBea5C99AA6E574D83f0A7C733F7e4D0`) holds Chimpers tokens and must be upgraded to:

1. **Migrate held tokens** — Call migration contract to exchange old tokens for new
2. **Switch collection reference** — Update internal `collection` variable to new contract
3. **Resume operations** — Buy/sell new Chimpers tokens going forward

**See:** `TOKENWORKS_BRIEF.md` for technical requirements to share with TokenWorks team.

**Chimpers Team Responsibility:** Coordinate with TokenWorks on upgrade timeline. Their upgrade can occur after migration contracts are deployed.

---

## Acceptance Criteria

### Smart Contracts
- [ ] All tests pass on mainnet fork
- [ ] Contracts deploy successfully to mainnet
- [ ] Contracts verified on Etherscan
- [ ] Claim flow works end-to-end (lock old → mint new)
- [ ] Admin functions work (close claims, claim unclaimed)
- [ ] Royalties return correct values via ERC2981

### Claim Website
- [ ] Wallet connection works (MM, Rabby, WalletConnect)
- [ ] Displays user's unmigrated tokens correctly
- [ ] Batch claim transaction executes successfully
- [ ] Deployed and accessible via provided URL

---

## Risk Factors

| Risk | Mitigation |
|------|------------|
| Smart contract vulnerability | Thorough testing; optional audit |
| TokenWorks upgrade delay | Migration works independently; TokenWorks can upgrade anytime after |
| Low migration adoption | Consider incentive; indefinite claim window reduces urgency pressure |
| Gas costs for large holders | Batch claiming reduces per-token gas; 100 token limit prevents failed txs |

---

