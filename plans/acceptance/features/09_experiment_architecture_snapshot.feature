@ACC-009 @REQ-020 @REQ-021 @CON-011 @CON-014 @CON-015 @REQ-001
Feature: Scaffold experiment-owned C++ model definitions
  As a contributor changing CNN architecture
  I want each experiment to carry its own editable `model.cpp`
  So that I can review, modify, and later port the architecture without depending on other experiments or the framework

  Scenario: Scaffold a non-base experiment from a base
    Given a tracked base experiment exists
    When I scaffold a new non-base experiment from that base
    Then the new experiment includes `experiment.toml`, `model.cpp`, and `notes.md`
    And the new experiment folder is the durable tracked source for that experiment in the repo
    And the new experiment's `model.cpp` starts from the base model definition
    And the copied `model.cpp` keeps the documented `build_model(int64_t input_channels, int64_t num_classes)` entrypoint
    And the copied `model.cpp` keeps the experiment provenance constant

  Scenario: Preserve experiment architecture when a later base changes
    Given an existing non-base experiment was scaffolded from a base
    When a later base version changes its default `model.cpp`
    Then the existing experiment still keeps its own copied model definition unchanged

  Scenario: Reject experiment-to-experiment inheritance for non-base work
    Given a contributor tries to scaffold a non-base experiment from another non-base experiment
    When validation runs
    Then the request fails with an actionable error telling the contributor to extend a base

  Scenario: Keep the production-portable artifact boundary clean
    Given a contributor wants to move a successful experiment toward production
    When the contributor copies the experiment `model.cpp` and the shared C++ model library
    Then the production artifact does not require Python orchestration code
    And the production artifact does not require TOML-defined architecture or quantization settings
    And dataset-dependent input channels and class count still enter through the model build entrypoint
