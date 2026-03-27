# ADR-0011: Shared C++ Library Additive Stability

## Status

accepted

## Context

Each successful experiment's `model.cpp` plus the shared C++ library form the
production-portable artifact set (ADR-0009). A contributor deploys by copying
those two things into a production repo and compiling; after that copy, the
workbench and the production build share no runtime link.

Experiments that have been copied to production, as well as experiments still
inside the workbench, depend on specific shared library classes and their
interfaces. If an existing shared library class is modified — even to add
behavior — the semantics of every experiment that references it can change. In
the workbench this is detectable through recompilation; in a production repo
it is silent because the copy has already diverged.

The same risk applies within the workbench itself: a base experiment that was
used to scaffold many derived experiments depends on the shared primitives
being stable so that re-running an older experiment still produces equivalent
results.

## Decision

New behavior in the shared C++ library is always introduced as new classes or
types. Existing shared library classes and their public interfaces are stable
once any experiment or production artifact references them.

This means:

- adding a new activation, normalization, block, or quantization variant means
  creating a new named class with its own header and implementation, not
  editing an existing one
- numerical behavior, constructor signatures, and output shapes of existing
  classes must not change after they appear in any committed experiment
- renaming or removing a class from the shared library is treated the same as
  a breaking API change: it requires a new class name and a deprecation
  notice, not an in-place edit
- the shared library may accumulate many variants over time; that is the
  expected and correct outcome of this policy
- the experiment-local `model.cpp` contains explicit class references, so
  contributors reading any experiment can see exactly which shared primitives
  it uses and know those primitives are frozen
- the stability rule has a deliberate exception for bugs, decided by whether
  the fix changes what a compiled binary computes:
  - bugs that do not change numerical output or public interface semantics —
    crashes, undefined behavior, memory corruption, resource leaks, and pure
    performance improvements — are fixed in place; no experiment can
    meaningfully depend on a crash or memory leak, and a performance fix
    produces identical outputs
  - bugs that do change numerical output or interface semantics — wrong
    formula, wrong axis, off-by-one arithmetic, wrong constructor default that
    affects gradient or output shape — require a new named class; the old class
    stays, acquires a deprecation comment explaining the known defect, and new
    experiments explicitly adopt the corrected variant; the stability rule does
    not resolve whether the old behavior was intentional — it keeps both
    histories available so the question can be answered per experiment

## Consequences

- The production-portability guarantee (ADR-0009) holds across workbench
  versions: a production copy of `model.cpp` plus the shared library from a
  known workbench state will compile identically using either the workbench
  copy or a snapshotted library copy.
- Historical experiments remain rerunnable without reconstructing old class
  behavior from git history.
- The shared library grows by accretion rather than by mutation, which keeps
  the history of available primitives legible and auditable.
- Experiments that want new behavior must explicitly adopt a new class rather
  than receiving silent upstream changes; this keeps the experiment folder as
  the honest owner of its architectural choices.
- Contributors adding new primitives should prefer naming that reflects the
  variant's specific properties rather than using generic names that may need
  to be extended later.
- Stage 5 build infrastructure must compile each experiment against the exact
  shared library classes referenced by its `model.cpp` and must not require
  source-level changes to that file when new shared library classes are added.

## Supersedes

- none

## Related IDs

- CON-017
- CON-015
- CON-014
- CON-011
- ADR-0007
- ADR-0008
- ADR-0009
