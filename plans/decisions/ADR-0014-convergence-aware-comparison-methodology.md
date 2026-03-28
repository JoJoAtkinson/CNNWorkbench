# ADR-0014: Convergence-Aware Comparison With Two Analytical Layers

## Status

accepted

## Context

Stage 8 (REQ-011) establishes that the compare command emits versioned reports
that preserve dataset, run profile, deployment target, runtime, and fallback
distinctions. ADR-0010 establishes TensorBoard as the per-run curve inspection
surface, derived from canonical raw metrics artifacts.

The existing compare contract is about labeling and separation — it ensures
runs are never silently mixed across unlike conditions. It does not define what
analytical content the report must produce to answer the question that matters
most during architecture exploration: *which model is better, and in what way?*

The research behind this decision confirms three problems with stopping at raw
metrics:

1. **Raw final accuracy is not enough.** Two models can reach the same best
   validation accuracy while differing dramatically in how quickly they
   converge, how stable training is, and whether they degrade after peak
   (overfit vs. untraining). Raw final metrics hide all of that.

2. **Multi-dataset averages mislead.** Raw accuracy averages across datasets
   with different scales and difficulty levels conflate unlike things. A model
   that dominates three datasets but fails on one can look mediocre on a simple
   average while its actual behavior is structurally different.

3. **Published results require self-interpreting artifacts.** The goal includes
   outside observers being able to clone the repository and understand what was
   tested and what happened without a live tracking server or platform account.
   Text-first artifacts must carry enough analytical structure to stand on their
   own.

Established benchmarks (DAWNBench, MLPerf Training) formalize this by measuring
end-to-end time to a defined quality target rather than relying on proxy metrics
or final-epoch snapshots. The ML evaluation literature (Demšar) supports
rank-based multi-dataset aggregation as the principled alternative to raw
accuracy averages. The research also distinguishes overfitting from optimization
instability from delayed generalization — treating them as separate regimes
rather than collapsed into a single "validation went down" reading.

External experiment tracking platforms (MLflow, W&B, Aim, ClearML, Neptune,
Comet) exist and are capable, but adopting any of them as the canonical
comparison surface would violate CON-005 (text-first versioned artifacts) and
create a required external dependency for interpreting results. The project
keeps text-first, git-archivable artifacts as the canonical record.

## Decision

Comparison is structured as two explicit analytical layers:

**Layer 1 — Observability (already decided by ADR-0010):** TensorBoard event
logs per run, derived by Python from raw `metrics.csv` artifacts, for per-run
curve inspection.

**Layer 2 — Decision layer (this ADR):** The compare report derives and
includes a canonical feature set from raw metrics artifacts. These features are
the primary outputs for architecture promotion discussions.

### Canonical derived feature set

For each run × dataset combination, the compare report computes:

- **Steps-to-target:** training steps (or epochs) to reach a defined
  per-dataset quality threshold. When a run never reaches the threshold within
  its training budget, this value is absent (not zero, not infinity) and the
  run is noted as "did not reach target." This makes the difference between
  "converged late" and "never converged" explicit rather than collapsed.
- **Budgeted best:** the best validation metric achieved within the training
  budget, regardless of whether the threshold was reached. This is always
  defined and supports comparison even when some runs never hit the target.
- **Peak-to-final drop:** (best validation metric) − (final validation metric).
  Positive values signal overfitting or untraining behavior. Zero or near-zero
  values indicate stable convergence. This is computed from the raw curve and
  does not require a separate held-out set.
- **Generalization gap:** training metric minus validation metric at final epoch,
  when both are logged by the trainer. This is an optional feature; its absence
  does not break the report schema.

### Multi-dataset aggregation

The overall comparison panel uses rank-based aggregation rather than raw metric
averages:

- For each dataset, runs are ranked by the primary quality metric (lower rank
  is better). Ties share the average rank.
- The compare report includes average rank per model variant across the selected
  dataset set. Lower average rank signals consistently better relative
  performance.
- A Pareto view pairing quality (budgeted best or steps-to-target) against
  convergence speed is included when at least two experiments are being
  compared, because speed and quality answer different questions and should not
  be collapsed into one number.

### Publishability requirements

Every run's provenance record shall include: model variant ID, dataset ID,
seed(s) used, git commit hash, and hardware kind (CPU, CUDA, FPGA-targeted).
These fields ensure a git-clone reader can contextualize all compare outputs
without any external system.

All derived features are recomputable from the canonical `metrics.csv` artifact.
No external tracking platform is required to reproduce, verify, or present
compare outputs. TensorBoard logs remain derived visualization artifacts
(ADR-0010) and are not the publishable analysis record.

### What this ADR does not decide

- Specific numeric quality thresholds per dataset. Those are dataset-specific
  and are deferred to experiment authoring conventions or a future per-dataset
  target registry.
- Whether to require multiple seeds per comparison run for variance estimation.
  Single-seed runs remain valid; the schema should accommodate multi-seed runs
  as an enhancement when they are available.
- Gradient norm logging. The research notes that gradient/update norm histories
  improve instability diagnosis, but this requires C++ trainer changes that are
  not currently scoped. Noted as a future enhancement opportunity.

## Consequences

- The compare command answers architectural questions (which model converges
  faster, is more stable, generalizes better) as first-class outputs rather
  than requiring contributors to eyeball overlapping TensorBoard curves.
- Results published via git are self-interpreting: run provenance plus derived
  features in text form give outside observers enough context to understand
  what was tested and what happened.
- The TensorBoard surface remains available for deep per-run curve inspection;
  it is not replaced or reduced by this decision.
- Adopting an external tracking platform later for convenience (search,
  notifications, team dashboards) is still possible, but any such platform
  remains a derived visualization layer and cannot displace the text-first
  compare report as the canonical publishable surface (CON-005).
- The "did not reach target" explicit signal prevents silent null comparisons
  where a failing run looks comparable to a converging one by sharing a final
  accuracy value.
- Stage 8 is now responsible for the full derived feature set and rank
  aggregation logic, not just label-preserving report structure.

## Supersedes

- none

## Related IDs

- REQ-011
- REQ-024
- CON-005
- CON-011
- ADR-0010
- ADR-0006
