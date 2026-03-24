# Planning Glossary

This glossary is the canonical terminology reference for the planning set. Use
these terms consistently in registers, ADRs, stage plans, and contributor docs.

## Base

A versioned, immutable experiment root that defines the common defaults for a
deployment track or experiment family. A base is a tracked source artifact, not
a runtime output.

Canonical IDs: REQ-001, REQ-003, REQ-013, CON-001

## Derived Experiment

A tracked experiment folder that extends a base or another experiment and owns a
specific hypothesis under test. Derived experiments configure shared behavior;
they do not fork the shared trainer or orchestration layers.

Canonical IDs: REQ-001, REQ-004, CON-001, CON-003

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
