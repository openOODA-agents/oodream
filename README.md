# `oodream`

Capacity-bounded episodic and semantic Merkle memory store (`remember` / `recall`) with deterministic hash placement and checksum-chain verification for [openOODA](https://openOODA.org) (`L7` • [`@openOODA-agents`](https://github.com/openOODA-agents)).

- **Subcommands**: `status`, `verify`, `inspect`, `scan [dir]`, `remember [dir]`, `recall`, `theme <name>`, `about`
- **Capabilities (`CapReg64`)**: `FsReadCap`, `FsWriteCap`, `EnvCap`
- **Bundle**: `@agents` (`oopm install @agents` or `oopm install oodream`)

## Usage

```sh
oodream remember .            # Index repository state into checksum-chained memory journal
oodream recall                # Query episodic & semantic agent memory entries
oodream verify                # Verify hash-chain integrity & FIFO capacity bounds
oodream about
```

## Build & Test

```sh
make build
make test
```
