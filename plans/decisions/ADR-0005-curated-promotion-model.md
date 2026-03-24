# ADR-0005: Curated Upstream Experiment History

## Status

accepted

## Context

The repo is meant to support many exploratory experiments without forcing the
upstream project to own every one of them. The contribution model already
assumes branches and forks are normal for experiment-heavy work.

## Decision

Keep the upstream `experiments/` tree curated. Default experiment-only work to
branches or forks, and reserve upstream merges for reusable framework changes,
maintained bases, docs, tests, or explicitly promoted experiments.

## Consequences

- Repo-local or fork-local IDs are valid and promotion may renumber them.
- Promotion discussions depend on compare reports and notes rather than the
  assumption that every experiment becomes upstream history.
- Contributor docs must keep ownership and review-routing rules explicit.

## Supersedes

- none

## Related IDs

- REQ-011
- REQ-012
- REQ-013
- CON-001
- CON-011
- ASM-005
