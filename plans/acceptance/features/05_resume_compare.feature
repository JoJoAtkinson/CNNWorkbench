@ACC-005 @REQ-010 @REQ-011 @CON-005
Feature: Resume, fine-tune, and compare runs
  So that continued experiments stay explicit and reviewable
  As a contributor
  I want checkpoint provenance and compare output to remain honest

  Scenario: Resume from a previous checkpoint
    Given a prior run produced a compatible checkpoint
    When the contributor selects initialization mode resume
    Then the checkpoint is resolved before launch
    And the new run records the resolved checkpoint source in its artifacts

  Scenario: Fine-tune with fresh optimizer state
    Given a prior run produced reusable model weights
    When the contributor selects initialization mode finetune
    Then the new run loads model weights
    And the optimizer state is initialized fresh for the new job

  Scenario: Compare mixed runs without collapsing labels
    Given the compare input includes experiments with different deployment targets or runtimes
    When the contributor runs compare
    Then the report preserves dataset, profile, target, runtime, and fallback distinctions
    And the output remains versioned and text-first
