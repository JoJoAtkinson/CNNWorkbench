# ADR-0009: Production-Portable Experiment Artifacts

## Status

accepted

## Context

CNN Workbench exists to help contributors explore CNN architecture variants
through tracked experiments. When an experiment succeeds and is ready for
deployment, the contributor needs to move the trained model and its code to a
production-targeted repository. If the model definition is entangled with the
experimentation framework — embedded in TOML config that requires the
resolution pipeline, or scattered across inheritance chains — extraction
becomes a manual reconstruction effort.

The project needs a clean line: artifacts that define the model must compile
and run without any dependency on the Python orchestration framework, TOML
config parsing, or experiment inheritance logic.

## Decision

The per-experiment C++ model definition file (`model.cpp`) plus the shared C++
library form the production-portable artifact set. TOML config stays behind
because it serves training and execution concerns that do not travel to
production.

This means:

- the experiment's `model.cpp` uses shared library types with explicit
  numerical values and compiles with only the shared library and LibTorch
- the shared library contains parameterized building blocks with no magic
  numbers; it has no dependency on the Python layer or TOML config parsing
- a contributor moving an experiment to production copies the experiment's
  `model.cpp` and the contents of the shared C++ library, then compiles
  against LibTorch in the production repo
- no TOML config, Python orchestration code, or experiment inheritance logic
  is required for that production compilation
- the shared library may be copied wholesale or selectively based on which
  primitives the experiment's model actually uses

## Consequences

- The architecture boundary (ADR-0007) and experiment ownership (ADR-0008)
  directly serve this portability requirement.
- The shared library must not introduce dependencies on the Python layer,
  config parsing, or experiment-specific paths.
- Build and CI should eventually verify that the shared library compiles
  independently of the orchestration layer.
- Contributors get a clear mental model: the experiment is creating the code
  that could be used in production; the framework just makes it easier to
  iterate on that code.
- Per-experiment compilation (REQ-008) and the three-tier boundary (CON-013)
  are consequences of this portability requirement.

## Supersedes

- none

## Related IDs

- REQ-001
- REQ-008
- REQ-021
- CON-013
- CON-015
- ADR-0007
- ADR-0008
