@ACC-002 @REQ-006 @REQ-025 @CON-007 @CON-019 @CON-020
Feature: Prepare datasets and surface runtime metadata
  So that resolution and runtime flows share one dataset contract
  As a contributor
  I want dataset preparation to be idempotent and explicit

  Scenario: Prepare a dataset through the shared catalog
    Given the dataset catalog defines a supported phase-1 dataset
    When the contributor runs the dataset preparation flow
    Then the dataset helper writes metadata.json with the supported fields
    And the dataset root is reusable on later runs

  Scenario: Keep plain resolve pure by default
    Given dataset metadata is missing for a requested dataset
    When the contributor runs resolve without ensure-datasets
    Then resolve fails with a clear next step
    And no dataset mutation occurs as part of the failed resolve

  Scenario: Repair missing metadata when explicitly requested
    Given dataset metadata is missing for a requested dataset
    When the contributor runs resolve with ensure-datasets
    Then dataset preparation repairs the missing metadata path
    And the resolved child config includes dataset runtime metadata

  Scenario: Catalog key, script filename, output folder, and dataset_targets all align
    Given a Phase 1 dataset entry exists in the catalog
    Then the catalog key matches the prepare_entrypoint module name segment
    And the output folder under datasets/ uses the same identifier
    And the value in batch.dataset_targets matches the catalog key
    And the fetch script file is named <catalog_key>.py under src/cnn_workbench/datasets/

  Scenario: Fetch script exposes a standard callable invoked by the orchestrator
    Given a Phase 1 fetch script for a dataset
    When the orchestrator calls prepare(output_dir)
    Then the function writes metadata.json to the given output_dir
    And the function is idempotent on repeated calls
    And the function raises on failure rather than returning silently

  Scenario: Fetch script is runnable standalone via the __main__ block
    Given a Phase 1 fetch script for a dataset and the workbench package is installed
    When the contributor runs python -m cnn_workbench.datasets.<id> --output-dir <path>
    Then the script writes metadata.json to the given path
    And the script exits with a non-zero code on failure

  Scenario: Fetch script keeps its behavior when siblings are absent
    Given a Phase 1 fetch script loaded in an environment where no sibling dataset scripts are importable
    When prepare(output_dir) is called
    Then the function completes without importing from sibling dataset scripts
