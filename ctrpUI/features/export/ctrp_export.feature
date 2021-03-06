Feature: Export

  @EXPORT_HIGH
  Scenario: EXPORT_01 Validate the new FDAAA field: fda_regulated_drug = YES
    Given I click to view xml of "NCI-2017-00384"
    Then the field "oversight_info.fda_regulated_drug = Yes" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_01a Validate the new FDAAA field: fda_regulated_drug = NO
    Given I click to view xml of "NCI-2017-00387"
    Then the field "oversight_info.fda_regulated_drug = No" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_01b Validate the new FDAAA field: fda_regulated_drug if empty then it should not be there
    Given I click to view xml of "NCI-2017-00390"
    Then the field "oversight_info.fda_regulated_drug" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_02 Validate the new FDAAA field: fda_regulated_device = Yes
    Given I click to view xml of "NCI-2017-00384"
    Then the field "oversight_info.fda_regulated_device = Yes" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_02a Validate the new FDAAA field: fda_regulated_device = NO
    Given I click to view xml of "NCI-2017-00387"
    Then the field "oversight_info.fda_regulated_device = No" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_02b Validate the new FDAAA field: fda_regulated_device if empty then it should not be there
    Given I click to view xml of "NCI-2017-00390"
    Then the field "oversight_info.fda_regulated_device" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_03 Validate the new FDAAA field: post_prior_to_approval = Yes
    Given I click to view xml of "NCI-2017-00384"
    Then the field "oversight_info.post_prior_to_approval = Yes" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_03a Validate the new FDAAA field: post_prior_to_approval = NO
    Given I click to view xml of "NCI-2017-00381"
    Then the field "oversight_info.post_prior_to_approval = No" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_03b Validate the new FDAAA field: post_prior_to_approval if empty then it should not be there
    Given I click to view xml of "NCI-2017-00385"
    Then the field "oversight_info.post_prior_to_approval" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_04 Validate the new FDAAA field: ped_postmarket_surv = Yes
    Given I click to view xml of "NCI-2017-00384"
    Then the field "oversight_info.ped_postmarket_surv = Yes" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_04a Validate the new FDAAA field: ped_postmarket_surv = NO
    Given I click to view xml of "NCI-2017-00391"
    Then the field "oversight_info.ped_postmarket_surv = No" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_04b Validate the new FDAAA field: ped_postmarket_surv if empty then it should not be there
    Given I click to view xml of "NCI-2017-00389"
    Then the field "oversight_info.ped_postmarket_surv" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_05 Validate the new FDAAA field: exported_from_us = Yes
    Given I click to view xml of "NCI-2017-00384"
    Then the field "oversight_info.exported_from_us = Yes" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_05a Validate the new FDAAA field: exported_from_us = No
    Given I click to view xml of "NCI-2017-00387"
    Then the field "oversight_info.exported_from_us = No" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_05b Validate the new FDAAA field: exported_from_us if empty then it should not be there
    Given I click to view xml of "NCI-2017-00390"
    Then the field "oversight_info.exported_from_us" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_06 Validate the new FDAAA field: model_description
    Given I click to view xml of "NCI-2017-00384"
    Then the field "study_design.interventional_design.model_description" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_06a Validate the new FDAAA field: model_description if empty then it should not be there
    Given I click to view xml of "NCI-2017-00387"
    Then the field "study_design.interventional_design.model_description" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_07 Validate the new FDAAA field: masking_description
    Given I click to view xml of "NCI-2017-00384"
    Then the field "study_design.interventional_design.masking_description" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_07a Validate the new FDAAA field: masking_description if empty then it should not be there
    Given I click to view xml of "NCI-2017-00387"
    Then the field "study_design.interventional_design.masking_description" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_08 Validate the new FDAAA field: gender_based = Yes
    Given I click to view xml of "NCI-2017-00384"
    Then the field "Eligibility.gender_based = Yes" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_08a Validate the new FDAAA field: gender_based = No
    Given I click to view xml of "NCI-2017-00387"
    Then the field "Eligibility.gender_based = No" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_08b Validate the new FDAAA field: gender_based EMPTY
    Given I click to view xml of "NCI-2017-00391"
    Then the field "Eligibility.gender_based" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_09 Validate the new FDAAA field: gender_description
    Given I click to view xml of "NCI-2017-00384"
    Then the field "Eligibility.gender_description" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_09a Validate the new FDAAA field: gender_description EMPTY
    Given I click to view xml of "NCI-2017-00387"
    Then the field "Eligibility.gender_description" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_10 Validate the new FDAAA field: expanded_access_nct_id
    Given I click to view xml of "NCI-2017-00384"
    Then the field "ind_info.expanded_access_nct_id" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_10a Validate the new FDAAA field: expanded_access_nct_id EMPTY
    Given I click to view xml of "NCI-2017-00387"
    Then the field "ind_info.expanded_access_nct_id" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_11 Validate the field: regulatory_authority has been removed
    Given I click to view xml of "NCI-2017-00387"
    Then the field "oversight_info.regulatory_authority" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_12 Validate the field: endpoint has been removed
    Given I click to view xml of "NCI-2017-00387"
    Then the field "study_design.endpoint" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_13 Validate the field: primary_outcome.outcome_safety_issue has been removed
    Given I click to view xml of "NCI-2017-00391"
    Then the field "primary_outcome.outcome_safety_issue" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_14 Validate the field: secondary_outcome.outcome_safety_issue has been removed
    Given I click to view xml of "NCI-2017-00391"
    Then the field "secondary_outcome.outcome_safety_issue" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_15 Validate the field: masking has been removed
    Given I click to view xml of "NCI-2017-00387"
    Then the field "study_design.interventional_design.masking" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_16 Validate the new value: Device Feasibility has been added in interventional_subtype
    Given I click to view xml of "NCI-2017-00387"
    Then the new value as "Device Feasibility" should be there in "study_design.interventional_design.interventional_subtype"

  @EXPORT_HIGH
  Scenario: EXPORT_17 Validate the new value: Sequential Assignment has been added in assignment
    Given I click to view xml of "NCI-2017-00387"
    Then the new value as "Sequential Assignment" should be there in "study_design.interventional_design.assignment"

  @EXPORT_HIGH
  Scenario: EXPORT_18 Validate the field: start_date_type
    Given I click to view xml of "NCI-2017-00387"
    Then the field "start_date_type" should be populated

  @EXPORT_HIGH
  Scenario: EXPORT_19 Validate the field: start_date
    Given I click to view xml of "NCI-2017-00387"
    Then the field "start_date" should be populated

  @EXPORT_HIGH
  Scenario: EXPORT_20 Validate the field: primary_compl_date
    Given I click to view xml of "NCI-2017-00387"
    Then the field "primary_compl_date" should be populated

  @EXPORT_HIGH
  Scenario: EXPORT_21 Validate the field: primary_compl_date_type
    Given I click to view xml of "NCI-2017-00387"
    Then the field "primary_compl_date_type" should be populated

  @EXPORT_HIGH
  Scenario: EXPORT_22 Validate the field: completion_date
    Given I click to view xml of "NCI-2017-00387"
    Then the field "completion_date" should be populated

  @EXPORT_HIGH
  Scenario: EXPORT_23 Validate the field: completion_date_type
    Given I click to view xml of "NCI-2017-00387"
    Then the field "completion_date_type" should be populated

  @EXPORT_HIGH
  Scenario: EXPORT_24 Validate the field: delayed_posting = Yes
    Given I click to view xml of "NCI-2017-00384"
    Then the field "delayed_posting = Yes" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_24a Validate the new FDAAA field: delayed_posting = NO
    Given I click to view xml of "NCI-2017-00391"
    Then the field "delayed_posting = No" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_24b Validate the new FDAAA field: delayed_posting if empty then it should not be there
    Given I click to view xml of "NCI-2017-00389"
    Then the field "delayed_posting" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_25 Validate the new value: Early Phase I has been added in Phase
    Given I click to view xml of "NCI-2017-00387"
    Then the new value as "Early Phase I" should be there in "phase"

  @EXPORT_HIGH
  Scenario: EXPORT_26 Validate the new FDAAA field: no_masking = Yes
    Given I click to view xml of "NCI-2017-00387"
    Then the field "study_design.interventional_design.no_masking" with "Yes" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_27 Validate the new FDAAA field: no_masking = No
    Given I click to view xml of "NCI-2017-00384"
    Then the field "study_design.interventional_design.no_masking" with "No" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_28 Validate the field: Sex = Male
    Given I click to view xml of "NCI-2017-00387"
    Then the field "eligibility.gender" with "Male" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_29 Validate the field: Sex = Female
    Given I click to view xml of "NCI-2017-00384"
    Then the field "eligibility.gender" with "Female" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_30 Validate the field: Sex = All
    Given I click to view xml of "NCI-2017-00391"
    Then the field "eligibility.gender" with "All" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_31 Validate the field: has_expanded_access = Yes
    Given I click to view xml of "NCI-2017-00384"
    Then the field "indinfo.has_expanded_access" with "Yes" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_32 Validate the field: has_expanded_access = No
    Given I click to view xml of "NCI-2017-00391"
    Then the field "indinfo.has_expanded_access" with "No" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_33 Validate the field: has_expanded_access = Unknown
    Given I click to view xml of "NCI-2017-00387"
    Then the field "indinfo.has_expanded_access" with "Unknown" should be there

  @EXPORT_HIGH
  Scenario: EXPORT_33a Validate the field: has_expanded_access if not selected then it should not be there
    Given I click to view xml of "NCI-2017-00390"
    Then the field "indinfo.has_expanded_access" should not be there

  @EXPORT_HIGH
  Scenario: EXPORT_34 Validate the field: expanded_access_status has been removed
    Given I click to view xml of "NCI-2017-00391"
    Then the field "expanded_access_status" should not be there