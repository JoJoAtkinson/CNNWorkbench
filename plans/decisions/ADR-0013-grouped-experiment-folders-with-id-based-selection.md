# ADR-0013: Grouped Experiment Folders With ID-Based Selection

## Status

accepted

## Context

Contributors want to organize experiments by theme or topic without turning
filesystem paths into a second experiment-identity layer. The current plan
already assumes build roots, run artifacts, compare inputs, and checkpoint
references are keyed by `experiment_id`, and the C++ compiler only needs the
resolved source path for the selected experiment's `model.cpp`.

If experiment grouping became part of the canonical selector contract, Python
commands would need path-aware arguments, artifact naming would become less
stable, and the simple experiment-id surfaces used by build, run, compare, and
checkpoint lookup would fragment.

## Decision

Experiments may live either directly under `experiments/` or under optional
group folders beneath it, but canonical experiment selection remains id-based.
Group folders are organization-only and are ignored by the machine-facing
contract.

This means:

- Python discovery walks `experiments/` recursively to find experiment folders
- the leaf experiment folder name must equal `experiment.id`
- `experiment.id` is repo-unique regardless of grouping path
- canonical CLI selectors remain `--experiment <id>` and
  `--experiments <id>...`; path-based selectors are not required
- the scaffolder still creates `experiments/<id>/` by default and does not
  require grouping-aware arguments
- contributors may later move an experiment folder under group namespaces for
  organization without changing its canonical id
- build roots, run artifact roots, compare inputs, and symbolic checkpoint
  references remain keyed by `experiment_id`, not by group path
- Python resolves the selected experiment id to its actual on-disk path before
  invoking the build system, so C++ compilation remains indifferent to grouping

## Consequences

- Group folders are available as a human organization tool without complicating
  command syntax or leaking folder structure into C++ or compiler behavior.
- Duplicate experiment ids anywhere under `experiments/` become a hard error.
- Reviewers and operators keep one simple selector contract even if the repo
  becomes more organized over time.
- Deployment target, runtime intent, and inheritance continue to come from
  authored config and parent chains, not from group folder names.

## Supersedes

- none

## Related IDs

- REQ-023
- CON-018
- REQ-001
- REQ-004
- REQ-008
- REQ-009
- REQ-010
- REQ-011
