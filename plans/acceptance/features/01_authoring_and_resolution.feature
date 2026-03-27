@ACC-001 @REQ-001 @REQ-002 @REQ-004 @REQ-005 @REQ-023 @CON-001 @CON-002 @CON-003 @CON-018
Feature: Scaffold and resolve an experiment chain
  So that config changes stay reviewable before training
  As a contributor
  I want to scaffold, validate, and resolve a derived experiment from a tracked base

  Scenario: Scaffold a repo-local derived experiment
    Given a tracked base experiment exists in the current repo
    When the contributor runs the scaffold command with a parent and slug
    Then the repo allocates the next valid repo-local experiment ID
    And the new experiment folder records its parent linkage
    And the generated notes template explains the hypothesis and fields under test

  Scenario: Resolve a grouped experiment by canonical id
    Given an experiment folder has been moved under an organization-only group path
    When the contributor runs check or resolve using the experiment id
    Then the command finds the experiment without requiring the group path
    And duplicate experiment ids anywhere under `experiments/` are rejected

  Scenario: Inspect the runtime effect before launch
    Given a derived experiment changes authored config fields
    When the contributor runs resolve with diff-from-parent
    Then the output shows the authored delta
    And the output shows the resolved runtime effect for each child run

  Scenario: Aggregate validation failures
    Given an authored experiment contains multiple blocking errors
    When the contributor runs check in a JSON-capable mode
    Then the output returns an errors array
    And each error item includes a path, code, severity, and message
