# Planning Glossary

This glossary is the canonical terminology reference for the planning set. Use
these terms consistently in registers, ADRs, stage plans, and contributor docs.

## Base

A versioned, immutable experiment root that defines the common defaults for a
deployment track or experiment family. A base is a tracked source artifact, not
a runtime output, and it is the scaffold source for experiment-owned
`model.cpp` files.

Canonical IDs: REQ-001, REQ-003, REQ-013, REQ-020, CON-001, CON-014

## Derived Experiment

A tracked experiment folder that extends a base and owns a specific hypothesis
under test. Derived experiments carry their own `model.cpp`, but they do not
fork the shared trainer or orchestration layers.

Canonical IDs: REQ-001, REQ-004, REQ-020, REQ-021, CON-001, CON-003, CON-014, CON-015

## Model Definition File

The experiment-owned `model.cpp` file that defines one experiment's model graph
using shared C++ primitives and explicit architecture numbers. This file is the
portable architecture artifact, not `experiment.toml`.

Canonical IDs: REQ-020, REQ-021, CON-013, CON-015

## Backbone

The shared CNN feature extractor implementation used by an experiment model. A
backbone is the whole structured model body, usually composed of named stages
that in turn repeat blocks.

Canonical IDs: REQ-019, CON-013

## Stage

A named section of a backbone that repeats one block family a configured number
of times. In `model.cpp`, a stage is represented by explicit composition code
and architecture numbers.

Canonical IDs: REQ-019, REQ-020, CON-013

## Block

A reusable composite unit constructed from the shared library and repeated
within a stage. A block is made of multiple primitive layers and owns the local
connection pattern for that unit.

Canonical IDs: REQ-019, CON-013

## Layer

A primitive operation inside a block or backbone implementation, such as
convolution, normalization, activation, or pooling. Layers are implementation
details of shared code, not the authored source-of-truth structure for
experiments.

Canonical IDs: REQ-019, CON-013

## Batch Run

One launch of one experiment. A batch expands into one child run per dataset in
the resolved dataset target set.

Canonical IDs: REQ-002, REQ-009

## Child Run

One concrete training job for one dataset and one run profile. A child run is
the machine-facing unit of execution and the unit that produces runtime
artifacts.

Canonical IDs: REQ-002, REQ-009, REQ-010

## Train Runtime

The requested execution intent for training, such as `cpu` or `accelerated`.
This field answers how training should run, not what deployment target the
experiment is intended for.

Canonical IDs: REQ-004, REQ-007, REQ-009, CON-002, CON-004

## Deploy Target

The deployment-oriented track or profile an experiment is targeting, such as
accelerated, CPU, or FPGA. This field answers what kind of deployment the work
is intended to support, not which backend the current machine will use.

Canonical IDs: REQ-003, REQ-011, REQ-012, CON-002, CON-010

## Track

The long-lived deployment family an experiment belongs to. Tracks determine the
correct base lineage and promotion context for accelerated, CPU-targeted, and
FPGA-targeted work.

Canonical IDs: REQ-003, REQ-013, CON-002

## Resolved Child Run

The fully materialized execution contract produced by Python resolution for one
dataset and one run profile. This contract is the only runtime input the C++
trainer consumes.

Canonical IDs: REQ-002, REQ-005, REQ-008, CON-003

## Authoring-Only Environment

An environment that may scaffold, validate, resolve, compare, and prepare
datasets but must not build or launch training because the required training
capabilities are unavailable.

Canonical IDs: REQ-004, REQ-007, CON-008
