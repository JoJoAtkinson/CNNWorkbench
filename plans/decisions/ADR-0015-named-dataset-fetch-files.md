# ADR-0015: Named Dataset Fetch Files With Copy-Paste Independence

## Status

accepted

## Context

Stage 3 (REQ-006) established a shared dataset catalog in `configs/datasets.toml`
with a `prepare_entrypoint` field using `module:function` syntax. The specific
file layout and naming pattern were left implicit, creating open questions about:

1. How contributors discover which file fetches a given dataset when reading
   the catalog or a config.
2. How the orchestrator discovers the prepare callable without a secondary
   lookup step.
3. How dataset-specific Python dependencies (e.g., `torchvision` for
   MNIST-family datasets) are handled when a contributor adds a new dataset
   that requires libraries not already in the workbench environment.

The earlier plan named `numbers` and `fashion` as the Phase 1 datasets but
did not codify the file layout as a testable invariant.

An alternative considered was a shared dataset base class that all fetch
modules must inherit. This approach adds coupling and means a breaking change
to the base affects every dataset at once.

Another alternative was treating `prepare_entrypoint` as the sole discovery
mechanism with no naming constraint. That allows arbitrary cross-module
references, requiring contributors to chase an indirection path from
`dataset_targets` value → catalog entry → `prepare_entrypoint` value → actual
file instead of following one consistent name.

## Decision

The dataset fetch layer is structured around a name-alignment invariant and
copy-paste independence:

### 1. One file per dataset, named after the dataset

Each dataset in the catalog has exactly one Python file at
`src/cnn_workbench/datasets/<dataset_id>.py`. The `<dataset_id>` is the same
string used everywhere: the `configs/datasets.toml` catalog key, the value in
`batch.dataset_targets`, the `datasets/<dataset_id>/` output folder, and the
`prepare_entrypoint` field value. No mapping table or alias is required.

### 2. Standard callable interface

Every fetch file must expose:

```python
def prepare(output_dir: str) -> None:
    """Fetch, format, and write the dataset to output_dir.

    Writes <output_dir>/metadata.json containing at minimum:
        {"input_channels": <int>, "num_classes": <int>}
    """
```

The orchestrator (`ensure_dataset()`, `prepare_datasets`) calls `prepare`
from `cnn_workbench.datasets.<dataset_id>` without a separate lookup.

The `prepare_entrypoint` field in `configs/datasets.toml` must follow the
pattern `cnn_workbench.datasets.<dataset_id>:prepare` and must match the
catalog key exactly. This provides explicit documentation and enables tooling
to validate alignment.

### 3. Standalone CLI mode

Every fetch file must include a `__main__` block. The block accepts at minimum
`--output-dir`, calls `prepare(output_dir)`, and exits with a non-zero code on
failure. The canonical invocation requires the workbench package to be
installed:

```bash
python -m cnn_workbench.datasets.numbers --output-dir ./datasets/numbers
```

The orchestrator already requires the package to be present (it imports
`cnn_workbench.datasets.<id>:prepare` at runtime), so on any host running the
workbench the package will be available for direct CLI use as well.

### 4. Copy-paste independence

Fetch scripts are self-contained units. They may duplicate utility code
across files. Scripts must not import from sibling dataset fetch scripts.

The only permitted shared import from within the datasets package is the
thin `_install_helper` module:

```python
from cnn_workbench.datasets._install_helper import ensure_packages
ensure_packages(["torchvision"])
```

`ensure_packages` silently no-ops when packages are already present and
installs them via `pip` when missing. This one shared helper is the only
cross-file dependency allowed in the datasets package.

## Consequences

- Adding a new dataset requires one file, one catalog entry, and the names
  align by definition. Contributors can find the fetch logic from the config
  value without documentation or tooling.
- The orchestrator resolves `prepare_entrypoint` by convention
  (`cnn_workbench.datasets.<id>:prepare`) and can also import the module
  dynamically by name without reading the catalog field.
- Scripts can grow independently without affecting each other. A broken
  dataset script only affects that dataset.
- The copy-paste cost is low because dataset fetch scripts are short and
  their shared logic is thin.

## Related IDs

REQ-006, REQ-025, CON-007, CON-019, CON-020, STAGE-03, ACC-002
