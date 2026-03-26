@ACC-008 @REQ-019 @CON-013 @REQ-001 @CON-003
Feature: Keep model composition readable and extensible in shared code
  So that contributors can inspect and change architecture or math behavior
  As a contributor
  I want experiment model code and shared C++ primitives to keep the implementation obvious

  Scenario: Read backbone and stage composition in shared code
    Given the shared library implements a reusable backbone or stage helper
    When a reviewer inspects the shared model code
    Then the reviewer can clearly see the named stages and their block repetition
    And the reviewer does not have to infer architecture from opaque sequential-builder code

  Scenario: Read block internals in shared code
    Given the shared library implements a reusable block family
    When a reviewer inspects the block implementation
    Then the reviewer can clearly see the internal layer order and connection pattern
    And the reviewer can identify where to modify block math without searching unrelated trainer code

  Scenario: Extend model composition without per-experiment code copies
    Given a contributor wants a new reusable block family
    When the contributor adds shared code for that block and references it from an experiment model
    Then the new block can be used without changing the trainer loop
    And the trainer loop does not need a bespoke per-experiment code path

  Scenario: Keep dataset-dependent values out of authored architecture config
    Given the trainer is building one resolved child run
    When the experiment model is constructed
    Then `input_channels` and `num_classes` are supplied through the model build entrypoint
    And authored TOML still does not define model graph or quantization sections
