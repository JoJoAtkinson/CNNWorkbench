@ACC-003 @REQ-007 @REQ-008 @CON-003 @CON-006 @CON-008
Feature: Diagnose environments and build the trainer
  So that contributors fail early on unsupported setups
  As a contributor
  I want doctor and build to share a deterministic environment contract

  Scenario: Report an authoring-only environment
    Given the contributor lacks local training capabilities
    When the contributor runs doctor
    Then the output reports authoring-only status
    And the output explains which commands remain allowed

  Scenario: Bootstrap pinned LibTorch for a supported platform
    Given the contributor is in a supported training environment
    When the contributor runs the bootstrap and build flow
    Then the selected LibTorch package comes from the project lock file
    And the archive is checksum-verified before extraction
    And the trainer is built under an environment-scoped build root

  Scenario: Avoid unnecessary trainer rebuilds
    Given the trainer has already been built successfully
    When only training and execution config changes
    Then the build fingerprint does not force a trainer rebuild
