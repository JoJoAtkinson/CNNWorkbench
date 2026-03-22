# Stage 3 Plan: Dataset Catalog And Preparation

This stage replaces fixture dataset assumptions with a real dataset contract and
shared preparation path.

## Purpose

- define how datasets enter the system
- make runtime metadata explicit and reusable
- keep dataset preparation in one Python-owned path

## Dependencies

- Stage 1 foundation
- Stage 2 resolution and validation flow

## Scope

- `configs/datasets.toml`
- shared dataset metadata loader interface
- `prepare_datasets`
- idempotent `ensure_dataset()`
- `numbers` and `fashion` dataset helpers
- `<dataset_root>/metadata.json` creation and validation
- `resolve --ensure-datasets`

## Out Of Scope

- local training
- environment build logic
- compare and matrix workflows

## Deliverables

- contributors can add a dataset through one documented catalog and helper path
- `resolve` can read runtime dataset metadata instead of relying on fixtures
- `run_local` and `resolve --ensure-datasets` can share the same preparation
  logic later

## Done Criteria

- dataset metadata is copied into resolved child configs
- `prepare_datasets` is idempotent
- plain `resolve` stays pure by default
- missing metadata produces a clear failure with the right next step

## Test Gate

- unit tests for catalog parsing and metadata validation
- integration tests for idempotent dataset preparation on fixture roots
- tests proving `resolve` fails cleanly when metadata is missing
- tests proving `resolve --ensure-datasets` repairs the missing metadata path

## Handoff To Stage 4

- Stage 4 should be able to use the real dataset contract without adding a
  second dataset-preparation path.
