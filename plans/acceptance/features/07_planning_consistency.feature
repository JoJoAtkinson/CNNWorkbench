@ACC-007 @REQ-014 @REQ-015 @REQ-016 @REQ-017 @REQ-018 @CON-005 @CON-009
Feature: Maintain the planning consistency layer
  So that the planning set stays auditable as it grows
  As a maintainer
  I want canonical records, trace links, and narrative docs to stay synchronized

  Scenario: Update planning artifacts in the required order
    Given a planning decision changes
    When the maintainer updates the planning set
    Then the canonical register is updated before the related ADR, trace, and narrative docs

  Scenario: Keep the architecture narrative current
    Given a design change affects an existing section of plan.md
    When the maintainer updates the narrative docs
    Then the affected section is rewritten in place to describe the current design
    And the section still points back to the relevant canonical IDs

  Scenario: Keep stage plans traceable
    Given a stage plan defines scope and acceptance gates
    When the maintainer reviews the stage plan
    Then the plan includes a non-empty Coverage section
    And the Coverage section lists the canonical requirements, constraints, acceptance artifacts, and collaboration risks

  Scenario: Publish a human checksum report
    Given the planning registers, ADRs, and trace links are current
    When the maintainer reviews the coverage report
    Then the report summarizes orphan requirements, verification gaps, blocking unknowns, stale supersession references, and collaboration-risk mapping status
