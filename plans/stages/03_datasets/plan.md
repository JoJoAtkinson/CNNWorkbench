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
- `configs/schemas/datasets_catalog.schema.json`
- shared dataset metadata loader interface
- `prepare_datasets`
- idempotent `ensure_dataset()`
- `numbers` and `fashion` dataset helpers, each as a named fetch file
  following the standard interface (`src/cnn_workbench/datasets/numbers.py`
  and `src/cnn_workbench/datasets/fashion.py`)
- `src/cnn_workbench/datasets/_install_helper.py` — thin utility for
  dependency self-installation used by fetch scripts
- standard `prepare(output_dir: str) -> None` callable in every fetch script
- `__main__` block in every fetch script for standalone CLI invocation
- `<dataset_root>/metadata.json` creation and validation
- top-level dataset catalog schema versioning
- strict Phase 1 `metadata.json` shape with only `input_channels` and
  `num_classes`
- sentinel-based cache reuse rules when a dataset declares a sentinel
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
- the catalog schema version and strict dataset metadata contract are explicit
  instead of being inferred from tests alone

## Coverage

- Implements: `REQ-006`, `REQ-025`
- Constrains: `CON-007`, `CON-019`, `CON-020`
- Verifies: `ACC-002`, `R4`, `R7`

## Done Criteria

- dataset metadata is copied into resolved child configs
- `prepare_datasets` is idempotent
- plain `resolve` stays pure by default
- missing metadata produces a clear failure with the right next step
- cache reuse requires both valid metadata and the configured sentinel when one
  is defined
- each Phase 1 fetch script (`numbers.py`, `fashion.py`) follows the standard
  `prepare(output_dir: str) -> None` interface and includes a `__main__` block
- the fetch script filename, catalog key, `dataset_targets` value, and output
  folder all use the same identifier for both Phase 1 datasets
- `_install_helper.ensure_packages` handles missing dependencies without
  requiring the contributor to pre-install dataset-specific libraries

## Test Gate

- unit tests for catalog parsing and metadata validation
- unit tests for `[schema].catalog_version` and the tracked schema reference
- integration tests for idempotent dataset preparation on fixture roots
- integration tests proving cache reuse requires both valid metadata and the
  sentinel when one is configured
- tests proving `resolve` fails cleanly when metadata is missing
- tests proving Phase 1 rejects extra persisted metadata keys
- tests proving `resolve --ensure-datasets` repairs the missing metadata path
- unit tests confirming `numbers.prepare` and `fashion.prepare` write valid
  `metadata.json` with `input_channels` and `num_classes`
- tests confirming each fetch script's `__main__` block exits non-zero on
  failure and zero on success
- tests confirming the `prepare_entrypoint` field in `configs/datasets.toml`
  matches the `cnn_workbench.datasets.<id>:prepare` pattern for each Phase 1
  dataset

## Collaboration Risks

- `R4`: Stage 3 keeps dataset schema and cache behavior explicit in the docs and
  tests.
- `R7`: Stage 3 defines which dataset artifacts are reusable local cache versus
  tracked contract inputs.

## Handoff To Stage 4

- Stage 4 should be able to use the real dataset contract without adding a
  second dataset-preparation path.

Canonical IDs: REQ-006, REQ-025, CON-007, CON-019, CON-020
