@ACC-004 @REQ-009 @CON-004 @CON-011 @CON-012
Feature: Execute local scratch runs with provenance
  So that short runs are a trustworthy contributor feedback loop
  As a contributor
  I want local execution to produce complete success and failure artifacts

  Scenario: Run a short local batch from scratch
    Given a resolved scratch-mode experiment targets more than one dataset
    When the contributor runs a short local batch
    Then the batch expands into ordered child runs
    And each child run writes the documented manifest and summary artifacts

  Scenario: Record failure artifacts before trainer launch
    Given a child run fails before the trainer process starts
    When run_local handles the failure
    Then the child run still writes resolved_config.toml, run_manifest.json, and summary.json
    And train.log is absent because the trainer never launched

  Scenario: Preserve git provenance expectations
    Given a contributor attempts a canonical full run from a dirty git tree
    When the dirty-tree override is not set
    Then the run is rejected according to the documented clean-tree policy
