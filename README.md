# `oodream`

Autonomous agent dreaming engine for [openOODA](https://openOODA.org) (`L7` • [`@openOODA-agents`](https://github.com/openOODA-agents)): offline memory consolidation into a checksum-chained episodic journal, counterfactual scenario synthesis, cross-domain connection discovery, and self-hosted LLM inference over `TcpCap` against the ooaid/oollama cluster (`OODA_AID_HOST`:`OODA_AID_PORT`, defaults `127.0.0.1:11435`) with active-active failover and deterministic offline fallback.

- **Subcommands**: `status`, `verify`, `inspect`, `scan [dir]`, `synthesize`, `dream [dir]`, `infer [prompt]`, `models`, `theme <name>`, `about`
- **Capabilities (`CapReg64`)**: `FsReadCap`, `FsWriteCap`, `EnvCap`, `TcpCap`
- **Bundle**: `@agents` (`oopm install @agents` or `oopm install oodream`)

## Usage

```sh
oodream dream /tmp/dream      # Consolidate + persist the episodic dream journal (.oot)
oodream synthesize            # Counterfactual synthesis pass over the scanned concept store
oodream infer "bridges"       # Self-hosted LLM inference via oostd pair_programmer (TcpCap+EnvCap)
oodream models                # Resolved LLM endpoint/model config (EnvCap)
oodream scan .                # Bounded .oo tree scan folded into the journal
oodream about
```

## Build & Test

```sh
make build
make test
```
