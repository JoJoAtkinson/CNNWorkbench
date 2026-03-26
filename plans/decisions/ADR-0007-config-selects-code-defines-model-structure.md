# ADR-0007: TOML Trains, C++ Model Code Defines Architecture

## Status

accepted

## Context

CNN Workbench is intentionally config-first for training and execution, but
model architecture is a different kind of concern. When architecture choices
such as stage counts, channel widths, block families, and quantization behavior
live in TOML, contributors have to bounce between the config file and C++ code
to understand what the model actually looks like. The architecture becomes
invisible at a glance.

The project also has a production-portability requirement: a successful
experiment's model code plus the shared C++ library must be extractable to a
production repo without any dependency on the Python orchestration framework
or TOML config parsing. If architecture lives in TOML, that portability
guarantee breaks because the production environment would need a TOML
interpreter and the full resolution pipeline.

The boundary needs three tiers instead of two:

TOML config is the right place for:

- epochs, batch size, and training hyperparameters
- dataset targets
- runtime intent and deployment target
- optimizer, scheduler, and loss selection and hyperparameters
- train loop selection and settings
- checkpoint and initialization behavior
- short-run schedule
- deployment export profile

Per-experiment C++ model code is the right place for:

- stage composition with explicit dimensions, block counts, and strides
- block family selection at each architecture level
- activation and normalization choices that define the model graph
- quantization mode, bit widths, and fake-quant toggle
- head configuration
- any architecture parameter that would need to travel to production
- a `constexpr std::string_view kExperimentId` provenance constant (see below)

Dataset-dependent values (`input_channels`, `num_classes`) are not architecture
constants and do not belong hardcoded in `model.cpp`. They arrive from the
resolved child config and are passed as parameters to `build_model`. The
`build_model` signature is:

```cpp
auto build_model(int64_t input_channels, int64_t num_classes) -> models::CompiledModel;
```

Shared C++ library code is the right place for:

- parameterized block implementations with no magic numbers
- parameterized layer primitives
- residual and connection patterns
- low-level math such as quantizers, shift activations, and barrel-shift norms
- optimizer implementation details

## Decision

Keep TOML config for training and execution settings. Move all model
architecture definition into per-experiment C++ model files. Keep shared
library code as the parameterized building-block layer with no magic numbers.

### Boundary test

When in doubt about whether a setting belongs in TOML config or in `model.cpp`,
apply this test:

**Forward direction — production portability:**
Pick up `model.cpp` and the shared C++ library and move them to a production
repo. Compile against LibTorch only. If the model requires a setting to run in
that production environment, that setting must live in `model.cpp` or the
shared library. It cannot live in TOML, because TOML stays behind in the
workbench.

**Inverse direction — experiment-only settings:**
When you pick up `model.cpp`, are there settings you need to delete because
they controlled how the experiment ran rather than what the model is? Those
settings belong in TOML. Things like learning rate, batch size, dataset
targets, and train-loop selection are experiment concerns, not model concerns.

**Worked example — `qat_int8`:**
`qat_int8` specifies weight quantization to 8 bits, activation quantization
to 8 bits, and fake-quant behavior. This configuration travels with the model
to production: an FPGA inference pipeline or a quantized accelerated deployment
uses exactly these bit widths. Removing or changing them in production would
break the model. Therefore `qat_int8` lives in `model.cpp`, not in a
`[quantization]` TOML section. A `[quantization]` section in TOML would mean
the model is incomplete without the resolution pipeline, which violates the
portability requirement.

**Provenance constant:**
The copy-paste mechanism severs the git history between the workbench and the
production repo. `kExperimentId` is a `constexpr std::string_view` declared at
file scope in each `model.cpp`. It compiles into the binary as a traceable
string. Keeping it in production is optional but strongly encouraged: it is the
only link back to the originating experiment once the code has been moved.

This means:

- each experiment folder contains a `model.cpp` that defines the experiment's
  architecture using shared library primitives with explicit values
- TOML config has no `[model]` or `[model.stageN]` sections
- TOML config has no `[quantization]` section; quantization is part of
  architecture
- the experiment's `model.cpp` plus the shared library form a
  production-portable artifact
- the build is per-experiment: `build --experiment <id>` compiles that
  experiment's model code with the shared library into a per-experiment binary
- scaffolding copies the base experiment's `model.cpp` as a starter template
- contributors modify architecture by editing C++ model code where stages,
  dimensions, and block counts are visible at a glance

## Consequences

- Architecture is visible in code at each depth level: stages, blocks, layers.
- No for-loop soup in model code; explicit stage composition is intentional.
- The production-portability requirement is satisfied: copy `model.cpp` and the
  shared library to compile a standalone model without the framework.
- The resolved child run scope narrows: no model architecture params in the
  resolved TOML. The per-experiment binary already has the model compiled in.
- Model component registries (backbone, block, norm, activation) become less
  central since experiments call shared library types directly in code.
- Non-model registries (optimizer, scheduler, loss, train_loop) continue to
  work via TOML and registry lookup.
- Stage 2 must scaffold `model.cpp` from the base template, not TOML model
  sections.
- Stage 5 must prove per-experiment compilation and readable model code.
- ADR-0008 defines how experiments own their model definition files.
- ADR-0009 captures the production-portability rationale.

## Supersedes

- none

## Related IDs

- REQ-001
- REQ-008
- REQ-019
- REQ-021
- CON-013
- CON-015
- ADR-0001
- ADR-0003
- ADR-0008
- ADR-0009
