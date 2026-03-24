@ACC-002 @REQ-006 @CON-007
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
