# ADR-0010: Python Owns TensorBoard Event Log Projection

## Status

accepted

## Context

Contributors want a familiar live-training monitor for loss, accuracy, and
other progress metrics. TensorBoard is a good fit for that workflow, but the
current runtime boundary already gives the C++ trainer a narrow ownership
surface: it runs one resolved child run and writes canonical raw artifacts such
as `metrics.csv`, checkpoints, and summary inputs. Python already owns artifact
orchestration and post-run interpretation.

If the C++ trainer writes TensorBoard event logs directly, the trainer gains a
visualization-specific dependency and the canonical metrics contract becomes
harder to keep portable and reviewable. The project also already treats
text-first artifacts as the collaboration surface, which means TensorBoard logs
should remain derived rather than canonical.

## Decision

Keep the trainer responsible for raw metrics artifacts and keep Python
responsible for TensorBoard projection.

This means:

- C++ writes canonical raw metrics such as `metrics.csv`
- Python reads those raw metrics artifacts and writes TensorBoard event logs
- TensorBoard event logs live under the run folder as derived visualization
  artifacts
- the trainer does not depend on TensorBoard libraries or event-log formats
- `metrics.csv`, `summary.json`, and other text-first artifacts remain the
  canonical review and reproducibility surface

## Consequences

- TensorBoard support fits the existing Python/C++ boundary instead of cutting
  across it.
- Visualization integrations can evolve in Python without changing the trainer
  contract.
- The C++ runtime remains simpler and more production-portable.
- TensorBoard event logs are regenerable from canonical raw metrics artifacts.
- Stage 6 owns the end-to-end behavior because it completes the runtime
  artifact story.

## Supersedes

- none

## Related IDs

- REQ-009
- REQ-022
- CON-003
- CON-005
- CON-016
- ADR-0003
- ADR-0006
