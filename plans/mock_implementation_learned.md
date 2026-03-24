# Mock Implementation Learned Notes

## Stage 1 Foundation

Open questions and plan gaps discovered while implementing:

1. ~~The plan calls several models (`EnvironmentReport`, `LaunchVerdict`, `RunManifest`, `BatchPlan`, `CompareInput`) "provisional" in Stage 1, but does not define which fields are mandatory now vs safe to defer. This made early validation scope ambiguous.~~ **Resolved by implementation:** All domain models are defined with concrete fields from the start and include `validate()` methods. `ExperimentConfig` requires all 15 sections. `RunManifest` has all manifest fields including matrix metadata. `EnvironmentReport`, `LaunchVerdict`, `BatchPlan`, and `CompareInput` are fully specified. Nothing is deferred. Fields exist from Stage 1 and are exercised incrementally as later stages introduce their callers. Canonical IDs: `REQ-002`, `STAGE-01`.
2. ~~Artifact schema versioning is required, but no compatibility policy is defined (for example: additive fields allowed under `1.x` or strict bump-per-change), which affects serializer tests and migration expectations.~~ **Resolved by final decision:** Persisted runtime artifacts use semantic-version compatibility. Additive optional fields may increment the minor version within the same major; breaking required-field changes require a major bump. Authored `experiment.toml` files remain current-schema only and do not carry a backward-compatibility promise. Canonical IDs: `CON-005`, `ADR-0006`, `STAGE-01`.
3. ~~Stage 1 asks for initial CI placeholder wiring but does not specify the minimum artifact (`workflow file`, `make test`, or both), so acceptance can vary by reviewer.~~ **Resolved by final decision:** The minimum tracked CI surface is at least one workflow file under `.github/workflows/` that runs the canonical command `make test`. Canonical IDs: `R3`, `STAGE-01`.
4. ~~The CLI surface is defined as module entrypoints (`cnn_workbench.cli.*`) but packaging expectations (console scripts vs `python -m`) are not explicitly required in Stage 1 done criteria.~~ **Resolved by implementation:** The CLI surface uses `python -m cnn_workbench.cli.*` module entrypoints. No console scripts are required. The mock trainer binary is generated as a Python script that invokes `cnn_workbench.trainer.binary.main` directly. Canonical IDs: `CON-008`, `R9`, `STAGE-01`.

## Stage 2 Authoring And Resolution

Open questions and plan gaps discovered while implementing:

1. ~~Experiment id allocation rules are under-specified for `--kind base` (for example `110` vs `111` when gaps exist), so scaffold behavior can diverge across implementations.~~ **Resolved by implementation:** `choose_next_id()` uses repo-local band-based allocation. The band is `(parent_prefix // 100) * 100`. For `kind == "base"`: candidate = next multiple of 10 (`((current_max // 10) + 1) * 10`). For experiments: candidate = `current_max + 1`. Gaps are consumed by incrementing until an unused prefix is found in the current repo. Fork-local ids are local; a promoted experiment may be renumbered when merged upstream. Canonical IDs: `REQ-001`, `REQ-013`, `STAGE-02`.
2. ~~`resolve --diff-from-parent` says to show authored delta plus runtime effect, but no output contract is defined (table vs JSON, path notation, ordering), which makes tests and downstream tooling brittle.~~ **Resolved by implementation:** `resolve_with_diff()` returns a dict with `parent` (id), `child` (id), `authored_delta` (flat dotted-key dict of child's authored values), `runtime_effect` (dict of `{dotted_key: {parent: value, resolved: value}}` for changed keys), and `resolved_children` (list of rendered child configs). Output is JSON-serializable with flat dotted-key notation. Canonical IDs: `REQ-004`, `REQ-005`, `REQ-002`, `STAGE-02`.
3. ~~Stage 2 requires preview runtime metadata (`resolved_backend`, `fallback_applied`) before Stage 4 environment detection exists; the plan does not define whether this should be assumed, omitted, or marked as provisional.~~ **Resolved by implementation:** `_resolve_backend_preview()` returns deterministic preview placeholders, `("cuda", False)` for `accelerated` and `("cpu", False)` for `cpu`, so preview resolution works without environment detection. Canonical IDs: `REQ-004`, `CON-004`, `STAGE-02`.
4. ~~Validation error aggregation is required, but there is no standard machine-readable error schema (`code`, `path`, `severity`) for `check` and `resolve` failures.~~ **Resolved by final decision:** JSON-capable commands emit a top-level `errors` array. Each error object uses `code`, `path`, `severity`, and `message`, with optional `hint` for common remediations. Canonical IDs: `REQ-005`, `STAGE-02`.
5. ~~The prohibition on authored `model.layers` arrays is clear, but migration guidance for users who already authored array-based experiments is missing.~~ **Resolved by final decision:** Unsupported legacy authored syntax hard-fails under the current engine. Historical experiments remain immutable and are not rewritten in place. Exact historical replay should use the matching repo revision and dependency lock; reruns under the current engine require a new tracked experiment and retraining from scratch. Canonical IDs: `REQ-004`, `CON-001`, `STAGE-02`.

## Stage 3 Dataset Catalog And Preparation

Open questions and plan gaps discovered while implementing:

1. ~~`configs/datasets.toml` has no schema version field, so catalog-shape evolution rules are unclear.~~ **Resolved by final decision:** `configs/datasets.toml` includes a top-level `[schema]` table with `catalog_version = "1.0.0"`, and the authoritative tracked schema reference lives at `configs/schemas/datasets_catalog.schema.json`. Canonical IDs: `REQ-006`, `CON-007`, `STAGE-03`.
2. ~~Sentinel semantics are under-defined: whether sentinel is authoritative, advisory, or required when `metadata.json` is present but stale.~~ **Resolved by implementation:** `ensure_dataset()` requires both valid `metadata.json` and sentinel presence for the cached path. If either is missing or metadata is invalid, re-preparation occurs. The sentinel is authoritative alongside valid metadata. Both must be present to skip preparation. Canonical IDs: `REQ-006`, `CON-007`, `STAGE-03`.
3. ~~The plan requires idempotent `ensure_dataset()` but does not define behavior when metadata is invalid and data files already exist (repair in place vs hard fail).~~ **Resolved by implementation:** `ensure_dataset()` does repair-in-place. When metadata is invalid, by catching `FileNotFoundError`, `ValueError`, and `json.JSONDecodeError`, the prepare function is re-invoked regardless of existing data files. The prepare function is expected to be idempotent and overwrites metadata. Canonical IDs: `REQ-006`, `CON-007`, `STAGE-03`.
4. ~~There is no explicit contract for dataset metadata extensibility beyond `input_channels` and `num_classes` (for example class names, mean/std, or sample counts), which affects forward compatibility.~~ **Resolved by final decision:** Phase 1 dataset metadata is fixed and strict. `metadata.json` contains exactly `input_channels` and `num_classes`; additional persisted keys are outside the Phase 1 contract and require an explicit plan update plus schema-version bump. Canonical IDs: `CON-007`, `STAGE-03`.
5. ~~`resolve --ensure-datasets` mutation scope is not explicitly stated for partial failures in multi-dataset batches (all-or-nothing vs best-effort per dataset).~~ **Resolved by implementation:** Two policies exist for different contexts. `resolve --ensure-datasets` is all-or-nothing. Any dataset preparation failure raises an exception and aborts resolution. `run_local` handles failures per-child. A failed dataset prepare marks that child as `failed` with a `dataset_prepare_failed` error and the batch continues or stops per `stop_on_failure`. Canonical IDs: `REQ-006`, `REQ-009`, `STAGE-03`, `STAGE-06`.

## Stage 4 Environment Detection And LibTorch Download

Open questions and plan gaps discovered while implementing:

1. ~~Environment classification criteria are described conceptually but not as deterministic detection rules (which probes, environment vars, and precedence), leading to inconsistent implementations.~~ **Resolved by implementation:** `detect_environment()` uses this precedence: (1) `CNNWB_ENV_KIND` override if set, (2) `DEVCONTAINER=1` to `dev_container`, (3) `CNNWB_CUDA_CONTAINER=1` to `cuda_container`, (4) Darwin + arm64 + MPS to `native_macos_mps`, (5) CPU available to `native_cpu`, (6) otherwise to `authoring_only`. All probes use `CNNWB_*` env vars with explicit precedence. Canonical IDs: `REQ-007`, `ADR-0004`, `STAGE-04`.
2. ~~The LibTorch bootstrap contract does not define version pinning strategy, checksum verification requirements, or upgrade policy.~~ **Resolved by final decision:** The project uses a single project-wide lock file at `configs/libtorch.lock.toml` with exact LibTorch version and SHA256 checksum per package variant. Downloads must be checksum-verified before extraction. `doctor` and `build` may warn about newer releases but must never auto-upgrade the pinned version. There is no per-experiment LibTorch pinning. Canonical IDs: `REQ-008`, `CON-006`, `STAGE-04`.
3. ~~The plan says Docker and Dev Container should share the CUDA path, but does not define precedence when both markers are present (classification/reporting ambiguity).~~ **Resolved by implementation:** Explicit precedence order: `CNNWB_ENV_KIND` > `DEVCONTAINER` > `CNNWB_CUDA_CONTAINER`. When both Dev Container and CUDA container markers are set, Dev Container wins. Canonical IDs: `REQ-007`, `ADR-0004`, `STAGE-04`.
4. ~~Fallback policy refers to "short/debug" runs, but `debug` is not a formal run profile in the current CLI contract, so policy predicates are ambiguous.~~ **Resolved by implementation:** Only `"short"` and `"full"` are valid run profiles. `ResolvedChildRun.validate()` enforces `run_profile in {"full", "short"}`. The "debug" profile does not exist. CPU fallback applies only when `run_profile == "short"`. Canonical IDs: `CON-004`, `STAGE-04`.
5. ~~Command gating is specified at a high level but does not provide a normative machine-readable policy table for CLI commands and environment states.~~ **Resolved by implementation:** `policies/launch.py` defines two explicit command sets: `AUTHORING_ONLY_ALLOWED = {"doctor", "new_experiment", "check", "resolve", "compare", "prepare_datasets"}` and `TRAINING_COMMANDS = {"build", "run_local", "run_matrix"}`. `evaluate_launch_policy()` implements deterministic gating using these sets plus environment report capabilities. Canonical IDs: `REQ-004`, `REQ-007`, `STAGE-04`.

## Stage 5 Trainer Build And Minimal Vertical Slice

Open questions and plan gaps discovered while implementing:

1. ~~Stage 5 requires CMake-based build output but does not define a minimum CMake contract (expected generator, toolchain flags, or reproducibility constraints), so "build succeeded" can mean different things.~~ **Resolved by final decision:** The minimum supported CMake version is `3.26`. The canonical trainer target name is `cnnwb_train`, and Phase 1 supports at least `Debug`, `RelWithDebInfo`, and `Release` build types. Canonical IDs: `REQ-008`, `R8`, `STAGE-05`.
2. ~~The trainer input contract lists required sections but does not specify strictness for unknown keys/sections on the C++ side (ignore vs fail), which impacts forward-compatibility behavior.~~ **Resolved by implementation:** The trainer ignores unknown keys and sections. It reads only the specific config paths it needs via `.get()`. `validate_registered_components()` checks only the 9 registry-mapped paths. Unknown fields pass through silently, providing forward compatibility. Canonical IDs: `REQ-002`, `CON-003`, `STAGE-05`.
3. ~~Checkpoint file format is not specified (PyTorch `.pt` serialization shape vs custom schema), making resume/finetune interoperability assumptions risky.~~ **Resolved by implementation:** Checkpoints use a defined key schema: `model_state`, `optimizer_state`, `scheduler_state`, `model_backbone`, `loaded_optimizer_state`, and `loaded_scheduler_state`. The mock uses JSON. The real implementation will use PyTorch `.pt` serialization with the same key structure. `validate_checkpoint_for_mode()` checks these specific keys. Canonical IDs: `REQ-010`, `STAGE-05`, `STAGE-07`.
4. ~~Trainer exit-code semantics are not documented (`validation failure` vs `runtime crash` vs `data issue`), which complicates robust orchestration and failure classification in Stage 6.~~ **Resolved by implementation:** Exit code `0` means success. Exit code `2` means validation or configuration error, including unknown components, shape errors, and initialization errors. Python treats any non-zero exit as `status = "failed"`. Canonical IDs: `REQ-009`, `STAGE-05`, `STAGE-06`.
5. ~~Build ownership between Python bootstrap and trainer compilation is clear conceptually, but the plan does not define how to detect stale binaries when Python-side contract versions change.~~ **Resolved by final decision:** Stale-binary detection uses `build/<platform_tag>/build_fingerprint.json`. The fingerprint includes `cpp/**`, tracked CMake files, platform, toolchain, build-type identity, `configs/libtorch.lock.toml`, and runtime artifact schema-version constants. Authored experiment config changes do not participate, so config-only changes do not rebuild. Canonical IDs: `REQ-008`, `CON-006`, `STAGE-05`.

## Stage 6 Local Scratch Runs

Open questions and plan gaps discovered while implementing:

1. ~~`batch_id` generation format is not specified (timestamp, monotonic counter, UUID), which affects reproducibility and cross-tool linking.~~ **Resolved by implementation:** `batch_id` uses UTC timestamp format `%Y%m%d%H%M%S` via `datetime.now(tz=timezone.utc).strftime(...)`. Batch folder name is `{batch_id}_local_{run_profile}`. Canonical IDs: `REQ-009`, `CON-005`, `STAGE-06`.
2. ~~The plan requires git patch capture but does not define expected behavior outside a git repo (fail, warn, or record `nogit` sentinel values).~~ **Resolved by implementation:** When `.git` does not exist, `_git_info()` returns `commit="nogit"`, `source_repo_url=""`, `dirty=False`, `working_patch=""`, and `staged_patch=""`. The run proceeds normally with these sentinel values and no warning or failure. Canonical IDs: `REQ-009`, `CON-011`, `STAGE-06`.
3. ~~Failure artifact requirements are clear for `summary.json`, but there is no canonical minimum for `train.log` and `run_manifest.json` when failure occurs before trainer launch.~~ **Resolved by implementation:** Pre-trainer failures, including dataset prepare, policy rejection, and checkpoint validation, produce both `run_manifest.json` and `summary.json` with `status="failed"`, plus `resolved_config.toml`. `train.log` is produced only when the trainer subprocess actually runs. `experiment_source.toml` is written before any failure path. Canonical IDs: `REQ-009`, `CON-005`, `STAGE-06`.
4. ~~Stage 6 does not explicitly state whether `run_local` should auto-trigger `build` or bootstrap when binaries are missing or fail fast with remediation instructions.~~ **Resolved by implementation:** `run_local()` auto-triggers `ensure_libtorch()` and `build_trainer_binary()` before launching training. Users do not need to run `build` separately first. Canonical IDs: `REQ-008`, `REQ-009`, `STAGE-06`.
5. ~~`stop_on_failure = true` behavior for statuses is defined, but batch-level exit semantics (`failed` vs `partial` when only preflight failures occur) are not fully pinned.~~ **Resolved by implementation:** Batch status algebra is: `{"succeeded"}` only to `"succeeded"`; all launched children failed to `"failed"`; mixed success and failure to `"partial"`; all `not_started` to `"failed"`. The return value uses `ok = batch_status in {"succeeded", "partial"}`. Preflight-only failures, with no trainer launch, produce `"failed"` status. Canonical IDs: `REQ-009`, `STAGE-06`.

## Stage 7 Resume And Fine-Tune

Open questions and plan gaps discovered while implementing:

1. ~~Symbolic checkpoint reference syntax is not specified (for example latest-run lookup format), so Python-side checkpoint resolution behavior is implementation-defined.~~ **Resolved by implementation:** Format is `latest:<experiment_id>[:<dataset_name>[:best|last]]`. Default dataset is the current child's dataset name. Default checkpoint is `best`. Resolution walks `runs/<experiment_id>/`, takes the latest batch dir, sorted last, finds the child dir ending with `_<dataset>`, and returns `checkpoints/<checkpoint_name>.pt`. Canonical IDs: `REQ-010`, `STAGE-07`.
2. ~~Checkpoint compatibility rules are underspecified beyond "incompatible"; concrete criteria (model key matching, optimizer param groups, scheduler class or version) are not enumerated.~~ **Resolved by implementation:** `validate_checkpoint_for_mode()` checks that (1) the `model_state` key exists, (2) `strict_model_load=true` requires `model_backbone` to match `model.backbone` in the resolved config, (3) `resume` with `load_optimizer_state` requires `optimizer_state`, and (4) `resume` with `load_scheduler_state` requires `scheduler_state`. Canonical IDs: `REQ-010`, `STAGE-07`.
3. ~~The interaction between `initialization.mode` and `load_optimizer_state` / `load_scheduler_state` flags is not fully normative (should conflicting values warn, fail, or auto-normalize).~~ **Resolved by implementation:** The mode takes precedence. `finetune` always uses fresh optimizer and scheduler state regardless of the load flags, with silent auto-normalization. `resume` respects both flags. Conflicting combinations, such as `finetune` with `load_optimizer_state=true`, are normalized to the mode semantics. Canonical IDs: `REQ-010`, `STAGE-07`.
4. ~~Provenance recording requires `checkpoint_source`, but the plan does not clarify whether artifacts should store the original symbolic reference, resolved absolute path, or both.~~ **Resolved by implementation:** Artifacts store only the resolved absolute path. After checkpoint resolution, `child["initialization"]["checkpoint_source"]` is overwritten with `str(resolved_checkpoint)`. The original symbolic reference is not preserved in run artifacts. Canonical IDs: `REQ-010`, `CON-005`, `STAGE-07`.
5. ~~Multi-dataset resume behavior is unclear when one dataset has a resolvable checkpoint and another does not, such as abort batch vs partial execution policy.~~ **Resolved by implementation:** Checkpoint resolution happens per-child in the execution loop. If one child's checkpoint fails, that child gets `status="failed"` with `checkpoint_validation_failed` error. The batch continues or stops per `stop_on_failure`. Each dataset's checkpoint is resolved independently, so one failure does not block others unless `stop_on_failure=true`. Canonical IDs: `REQ-010`, `STAGE-07`.

## Stage 8 Compare And Matrix

Open questions and plan gaps discovered while implementing:

1. ~~Matrix definition schema is not formalized (axes-only, explicit variant tables, precedence rules when both are present), so parser behavior can diverge.~~ **Resolved by implementation:** `load_matrix_variants()` supports three input shapes: `axes`, as a dict of key to list for cartesian product, `variants`, as an explicit list of `{overrides: {...}}` tables, or both, with axes-expanded variants first and explicit variants appended after them. Matrix name defaults to file stem unless `name` is provided. Duplicate override sets and variant-id collisions are rejected. Canonical IDs: `REQ-011`, `STAGE-08`.
2. ~~Deterministic matrix variant-id generation is required but no canonical algorithm is specified (hash inputs, normalization, length), making cross-implementation reproducibility uncertain.~~ **Resolved by implementation:** The algorithm uses canonical JSON via `json.dumps(overrides, sort_keys=True, separators=(",", ":"))`, then SHA1, then the first 10 hex characters. Variant ID format is `{base_experiment}__mx_{sha1_hex[:10]}`. Canonical IDs: `REQ-011`, `STAGE-08`.
3. ~~"Latest completed batch" selection logic is not fully pinned when there are multiple statuses (`succeeded`, `partial`) or same-timestamp collisions.~~ **Resolved by implementation:** `_find_latest_completed_batch()` lists batch dirs matching the `_local_{run_profile}` suffix, reverse-sorts by directory name, timestamp based, and selects the first batch whose `batch_summary.json` has `status in {"succeeded", "partial"}`. Same-timestamp collisions resolve by directory sort order. Canonical IDs: `REQ-011`, `STAGE-08`.
4. ~~Compare output contract is descriptive but not machine-schema-defined, which limits stable downstream automation and report tooling.~~ **Resolved by implementation:** The compare output is a versioned dict from `versioned_compare_report()` containing `run_profile`, `experiments`, and `rows[]`. Each row has `dataset` and `experiments.{id}` with fields for `status`, `best_val_accuracy`, `best_val_loss`, `duration_seconds`, `tags`, `initialization_mode`, `train_runtime`, `resolved_backend`, `fallback_applied`, `deploy_target`, `matrix_variant_id`, and `smoke_validation`. Missing datasets get `{"status": "missing"}`. Canonical IDs: `REQ-011`, `CON-005`, `STAGE-08`.
5. ~~The deployment smoke-validation concept (export, load, infer, compatibility) is required, but concrete pass or fail criteria per step are not explicitly specified.~~ **Resolved by implementation:** `_deployment_smoke_validate()` checks four criteria: `export_ok`, `load_ok`, `inference_ok`, and `target_compatible`. The FPGA compatibility check validates qat_int8 mode, 8-bit weights and activations, fake quant, `fpga_int8_v1` export profile, `shift_activation`, and `barrel_shift_norm`; non-FPGA paths treat compatibility as true. `passed` requires all four criteria. Canonical IDs: `REQ-011`, `REQ-012`, `STAGE-08`, `STAGE-09`.

## Stage 9 FPGA Deployment Extension

Open questions and plan gaps discovered while implementing:

1. ~~FPGA constraint enforcement is tied to `fpga_int8_v1`, but the plan does not define how multiple future FPGA profiles should compose or inherit constraints.~~ **Resolved by final decision:** Phase 1 FPGA profiles are independent named profiles. Phase 1 does not introduce profile inheritance or profile composition. If future profiles duplicate substantial constraint logic, a later plan revision may add explicit shared profile composition. Canonical IDs: `REQ-012`, `CON-010`, `UNK-003`, `STAGE-09`.
2. ~~It is unclear whether non-FPGA deploy targets may intentionally use FPGA-friendly components (`shift_activation`, `barrel_shift_norm`) for experimentation without validation warnings.~~ **Resolved by implementation:** Non-FPGA experiments may use `shift_activation` and `barrel_shift_norm` without warnings. These components are registered globally in `REGISTRY_FAMILIES`. Constraint enforcement in `_enforce_deployment_constraints()` only fires for the `fpga_int8_v1` profile, so other tracks are unconstrained. Canonical IDs: `REQ-012`, `STAGE-09`.
3. ~~The shared smoke harness is required, but hardware-realistic FPGA validation boundaries (latency budgets, quantization calibration, export operator whitelist) are not specified.~~ **Resolved by final decision:** Shared smoke validation remains the Phase 1 baseline. Promotion-grade FPGA decisions require an additional hardware gate covering export operator whitelist compatibility, quantization or calibration validity, latency budget compliance, and resource or utilization budget compliance when hardware reports it. Canonical IDs: `REQ-012`, `R4`, `STAGE-09`.
4. ~~Compare labels tracks clearly, but the plan does not define whether cross-track ranking should be discouraged or blocked in certain promotion workflows.~~ **Resolved by implementation:** Cross-track comparison is allowed. `compare_experiments()` accepts any mix of experiments regardless of deploy target. Each experiment row includes `deploy_target` so downstream consumers can make informed ranking decisions. Neither warnings nor blocks are issued for cross-track comparisons. Canonical IDs: `REQ-011`, `REQ-012`, `STAGE-08`, `STAGE-09`.
5. ~~Fallback semantics for `train_runtime="accelerated"` on FPGA-targeted experiments in CPU-only environments are implied but not explicitly codified for promotion vs debug runs.~~ **Resolved by implementation:** FPGA-targeted experiments follow the same fallback policy as all other tracks. `train_runtime="accelerated"` with no CUDA or MPS and `run_profile="short"` falls back to CPU, as tested in `test_fpga_trainer_smoke_uses_registered_fpga_components`. Full runs must fail. No FPGA-specific fallback override exists. Canonical IDs: `REQ-012`, `CON-004`, `STAGE-09`.

## Resolution Index

This appendix restates each resolved question as a stable rule or decision for future plan reviews.

### Stage 1 Foundation

1. Domain models are fully defined from Stage 1. `ExperimentConfig`, `EnvironmentReport`, `LaunchVerdict`, `RunManifest`, `BatchPlan`, and `CompareInput` are not provisional shells.
2. Persisted runtime artifacts use semantic-version compatibility. Additive optional fields are allowed within the same major; breaking required-field changes require a major bump. Authored `experiment.toml` stays current-schema only.
3. The minimum CI placeholder is one tracked workflow under `.github/workflows/` that runs `make test`.
4. The CLI contract is `python -m cnn_workbench.cli.*`. Console-script packaging is not required for Phase 1.

### Stage 2 Authoring And Resolution

1. Experiment id allocation uses repo-local band-based numbering. Base experiments take the next multiple of 10 in the band; child experiments increment by 1 while skipping used ids. Fork-local ids are not globally authoritative and may be renumbered if the experiment is promoted upstream.
2. `resolve --diff-from-parent` uses a machine-readable JSON shape with `parent`, `child`, `authored_delta`, `runtime_effect`, and `resolved_children`.
3. Preview resolution uses deterministic placeholders for runtime metadata before real environment detection exists.
4. JSON-capable validation commands emit a top-level `errors` array. Each error object has `code`, `path`, `severity`, `message`, and optional `hint`.
5. Unsupported legacy authored syntax hard-fails. Historical experiments are not rewritten in place; reruns under the current engine require a new tracked experiment and retraining.

### Stage 3 Dataset Catalog And Preparation

1. `configs/datasets.toml` carries a top-level `[schema]` table with `catalog_version = "1.0.0"`, backed by `configs/schemas/datasets_catalog.schema.json`.
2. Dataset cache reuse requires both valid `metadata.json` and the sentinel. Missing or invalid metadata causes re-preparation.
3. Invalid dataset metadata triggers repair-in-place rather than a hard stop, and prepare routines are expected to be idempotent.
4. Phase 1 dataset metadata is fixed and strict: `metadata.json` contains exactly `input_channels` and `num_classes`.
5. `resolve --ensure-datasets` is all-or-nothing. `run_local` handles dataset failures per child and respects `stop_on_failure`.

### Stage 4 Environment Detection And LibTorch Download

1. Environment detection follows a fixed precedence order using explicit env-var probes, with `CNNWB_ENV_KIND` override first and `authoring_only` as the final fallback.
2. LibTorch is pinned project-wide in `configs/libtorch.lock.toml` with exact version and SHA256 checksum. Downloads are checksum-verified. The tool may warn about newer releases but does not auto-upgrade.
3. When both Dev Container and CUDA container markers are present, Dev Container wins.
4. The only formal run profiles are `short` and `full`. CPU fallback for accelerated runs is permitted only in `short`.
5. Launch gating is driven by explicit authoring-only and training command sets plus the detected environment capabilities.

### Stage 5 Trainer Build And Minimal Vertical Slice

1. The minimum supported CMake version is `3.26`. The canonical trainer target is `cnnwb_train`, and the supported build types are at least `Debug`, `RelWithDebInfo`, and `Release`.
2. The trainer ignores unknown config keys and sections. Forward compatibility is preserved by reading only the needed config paths.
3. Checkpoints use a defined key schema centered on `model_state`, `optimizer_state`, `scheduler_state`, and `model_backbone`, regardless of whether the transport is mock JSON or real `.pt`.
4. Trainer exit code `0` means success. Exit code `2` means validation or configuration failure. Any non-zero exit is treated as a failed run by orchestration.
5. Stale-binary detection uses `build/<platform_tag>/build_fingerprint.json`. The fingerprint includes C++ sources, tracked CMake files, platform/toolchain/build-type identity, `configs/libtorch.lock.toml`, and runtime artifact schema-version constants. Authored experiment config changes do not trigger rebuilds.

### Stage 6 Local Scratch Runs

1. `batch_id` is a UTC timestamp in `%Y%m%d%H%M%S` format, and batch folders are named `{batch_id}_local_{run_profile}`.
2. Outside git, run metadata records `commit="nogit"`, `source_repo_url=""`, and empty patches, then continues without failure.
3. Pre-trainer failures still write `experiment_source.toml`, `resolved_config.toml`, `run_manifest.json`, and `summary.json`. `train.log` exists only if the trainer process actually launched.
4. `run_local` auto-runs LibTorch bootstrap and trainer build. Users do not need to invoke `build` first.
5. Batch status is computed from child statuses: all success is `succeeded`, mixed outcomes are `partial`, and preflight-only or all-failed batches are `failed`.

### Stage 7 Resume And Fine-Tune

1. Symbolic checkpoint references use `latest:<experiment_id>[:<dataset_name>[:best|last]]`.
2. Resume and finetune compatibility checks are explicit: required checkpoint keys must exist, backbone matching is enforced when requested, and optimizer or scheduler state is required only when the selected mode and flags need it.
3. Initialization mode wins over load flags. `finetune` always starts with fresh optimizer and scheduler state.
4. Run artifacts store the resolved absolute checkpoint path, not the original symbolic reference.
5. Checkpoint failures are handled per child. One dataset failing checkpoint resolution does not block the others unless `stop_on_failure=true`.

### Stage 8 Compare And Matrix

1. Matrix definitions support `axes`, explicit `variants`, or both. When both are present, axes-generated variants come first and explicit variants append after them.
2. Matrix variant ids are deterministic: canonical JSON of overrides, SHA1 hash, first 10 hex characters, formatted as `{base_experiment}__mx_{hash}`.
3. Latest completed batch selection reverse-sorts batch directories and accepts the first batch whose summary status is `succeeded` or `partial`.
4. Compare output uses a versioned machine-readable report with run profile, experiments, and dataset rows carrying per-experiment metrics and run metadata.
5. Deployment smoke validation passes only if export succeeds, load succeeds, inference artifacts exist, and the target-specific compatibility check succeeds.

### Stage 9 FPGA Deployment Extension

1. Phase 1 FPGA deploy profiles are independent named profiles. There is no inheritance or profile composition yet.
2. FPGA-friendly components such as `shift_activation` and `barrel_shift_norm` are allowed outside FPGA deploy targets without warnings.
3. Shared smoke validation remains the baseline. Promotion-grade FPGA decisions add a hardware gate for export operator whitelist compatibility, quantization or calibration validity, latency budget compliance, and resource or utilization budget compliance when hardware reports it.
4. Cross-track compare is allowed. Reports carry `deploy_target` so consumers can decide how to rank mixed-target results.
5. FPGA-targeted runs use the same accelerated-runtime fallback policy as other tracks: `short` may fall back to CPU, while `full` must fail if no accelerated backend is available.
