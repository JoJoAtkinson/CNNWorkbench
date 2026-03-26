@ACC-006 @REQ-003 @REQ-012 @REQ-013 @CON-010
Feature: Validate FPGA-targeted experiments through the shared system
  So that FPGA work stays inside the shared architecture
  As a contributor
  I want explicit FPGA-targeted constraints and promotion checks

  Scenario: Resolve an FPGA-targeted experiment
    Given an FPGA-targeted experiment extends the FPGA base
    When the contributor resolves the experiment
    Then the experiment uses the shared core path
    And FPGA-specific constraints are enforced through explicit profile checks

  Scenario: Keep FPGA profiles independent in phase 1
    Given more than one FPGA deploy profile exists
    When a contributor selects one profile
    Then the profile does not inherit or compose rules implicitly from another profile

  Scenario: Review promotion-grade FPGA evidence
    Given an FPGA-targeted run is being considered for promotion
    When the reviewer inspects the validation evidence
    Then the evidence includes the shared smoke-validation baseline
    And the evidence includes the documented hardware gate criteria
