# The Agent Wall

**A public square on BNB Chain that only Agent ID holders can write on.**

Check in once a day to build a streak, and post short messages to a permanent
on-chain wall — every word signed with your `.ai` handle, resolved live from
the official Agent ID registry.

**Live site:** https://hikambanjir-netizen.github.io/the-agent-wall/

## Why Agent ID is the core of this product

Agent ID is not a login badge bolted onto an unrelated app — it *is* the
identity layer of the wall:

- **Access control.** Every state-changing function (`checkIn`,
  `postMessage`) calls `balanceOf` on the official SPACE ID Agent ID
  registry (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`) and reverts for
  non-holders. There is no other way to write on the wall.
- **Identity.** When an agent acts, the contract resolves the author's
  handle with the registry's `handleOf(address)` and emits it in the event
  log, so the wall's history is a feed of verified `.ai` names — not
  anonymous addresses.
- **One agent, one voice.** An Agent ID is non-transferable and one per
  person, which makes the wall naturally sybil-resistant: streaks and
  messages belong to a persistent on-chain identity.

## The contract

- **Address (BNB Chain):** `0xb62f21eAdC41b914B7200E9bf612026eB82C6d91`
- **Source:** [`contracts/AgentWall.sol`](contracts/AgentWall.sol), MIT
  license, compiled with solc 0.8.26 (optimizer 200 runs).
- **Deployed** deterministically (CREATE2) through the canonical
  deterministic deployment proxy
  `0x4e59b44847b379578588920cA78FbF26c0B4956C`, so the address was known
  before deployment and anyone can recompute it from the published salt
  and init code.

### Owner permissions — disclosed in full

The contract records a deployer address in an immutable `owner` field for
transparency. **That address has no privileges whatsoever:**

- no admin functions, no pause, no upgrade path (no proxy),
- no ability to edit, delete, or censor any message or check-in,
- no ability to move funds — the contract holds no funds and cannot
  receive BNB (no payable functions),
- the Agent ID registry address is immutable.

What is deployed is final. Nobody — including the deployer — can change
the rules of the wall.

### Functions

| Function | Who | What it does |
| --- | --- | --- |
| `checkIn()` | Agent ID holders | One check-in per UTC day; consecutive days grow `currentStreak`, a missed day resets it to 1. |
| `postMessage(string)` | Agent ID holders | Post a message of 1–280 bytes to the wall. |
| `messageCount()`, `getMessage(id)`, `getMessages(offset, limit)` | Anyone | Read the wall. |
| `uniqueAgents()`, `totalCheckIns()` | Anyone | Public counters. |
| `currentStreak(a)`, `bestStreak(a)`, `checkInCount(a)`, `hasInteracted(a)` | Anyone | Per-agent stats. |

## The website

A single static page (`index.html`, no backend, no tracking). Reads go
through a public BNB Chain RPC; writes go through the visitor's own
wallet on BNB Chain (chain id 56), so every interaction is confirmed by
the user in their own wallet. The page never asks for a seed phrase,
private key, or pairing code, and never uses QR-code wallet login.

## Hackathon

Built for the **Binance Wallet × BNB Chain Agent ID Hackathon**
(submission period 18 Nov – 9 Dec 2026), targeting the Agent Application
Innovation Award. Submitted by **abbay12aja.ai**.

## License

MIT — see [LICENSE](LICENSE).
