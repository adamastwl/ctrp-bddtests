require_relative '../support/dataclinicaltrials_api_helper.rb'
require_relative '../support/organization_helper.rb'
require_relative '../support/helper.rb'
require 'json'
require 'rest-client'

require 'nokogiri'
require 'time'
require 'active_support'

class Ct_api_helper

  def self.import_trial_frm_ct(arg1)
    headers = {:content_type => 'application/json', :accept => 'application/json'}
    ct_env = ENV['ctgov'].to_s
    nct_id = arg1.to_s
    url_ctgov = ''+ ct_env +'/NCT'+ nct_id +'/xml'
    @nct_id = 'NCT'+ nct_id
    @response_ctgov = Helper.request('get', url_ctgov, '', '', nil, {})
    @data_xml_ctgov = Nokogiri::XML(@response_ctgov)
    @response_json_ctgov = Hash.from_xml(@response_ctgov).to_json
    @data_hash_ctgov = JSON.parse(@response_json_ctgov)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    @conn.exec("update study_protocol set status_code = 'INACTIVE' where nct_id in ('" + @nct_id + "')")
    @conn.close if @conn
    @response, @response_code = Import_helper.trigger_import_post('POST', 'import', ENV['user2'], ENV['user2_password'], headers, @nct_id)
    return @nct_id, @data_hash_ctgov, @response, @response_code
  end

  def self.verify_json_element_with_db(db_field, nct_id, data_hash_ctgov)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    case db_field
      when 'Lead Org Trial ID'
        if data_hash_ctgov['clinical_study']['id_info']['org_study_id'].nil?
          flunk 'Please provide correct NCT_ID: <<' + nct_id + '>> Unable to find <<' + db_field + '>> value in the xml'
        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['id_info']['org_study_id'] + '>>.'
          @exp_lead_org = data_hash_ctgov['clinical_study']['id_info']['org_study_id']
        end
        @res = @conn.exec("SELECT lead_org_id FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @act_lead_org = @res.getvalue(0, 0)
        assert_equal(@act_lead_org.to_s, @exp_lead_org.to_s, 'Validating lead ORG ID')
      when 'Other ID'
        if data_hash_ctgov['clinical_study']['id_info']['secondary_id'].nil?
          flunk 'Please provide correct NCT_ID: <<' + nct_id + '>> Unable to find <<' + db_field + '>> value in the xml'
        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['id_info']['secondary_id'] + '>>.'
          @exp_other_id = data_hash_ctgov['clinical_study']['id_info']['secondary_id']
        end
        @res = @conn.exec("SELECT extension FROM public.study_otheridentifiers where identifier_name = 'Study Protocol Other Identifier' AND study_protocol_id in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @act_other_id = @res.getvalue(0, 0)
        assert_equal(@act_other_id.to_s, @exp_other_id.to_s, 'Validating Secondary ID or Other ID')
      when 'NCT ID'
        if data_hash_ctgov['clinical_study']['id_info']['nct_id'].nil?
          flunk 'Please provide correct NCT_ID: <<' + nct_id + '>> Unable to find <<' + db_field + '>> value in the xml'
        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['id_info']['nct_id'] + '>>.'
          @exp_nct_id = data_hash_ctgov['clinical_study']['id_info']['nct_id']
        end
        @res = @conn.exec("SELECT nct_id FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @act_nct_id = @res.getvalue(0, 0)
        assert_equal(@act_nct_id.to_s, @exp_nct_id.to_s, 'Validating NCT ID')
      when 'brief title'
        if data_hash_ctgov['clinical_study']['brief_title'].nil?
          flunk 'Please provide correct NCT_ID: <<' + nct_id + '>> Unable to find <<' + db_field + '>> value in the xml'
        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['brief_title'] + '>>.'
          @act_brf_ttle = data_hash_ctgov['clinical_study']['brief_title']
        end
        @res = @conn.exec("SELECT public_tittle FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @exp_brf_ttle = @res.getvalue(0, 0)
        assert_equal(@exp_brf_ttle, @act_brf_ttle, 'Validating Brief Title')
      when 'official title'
        if data_hash_ctgov['clinical_study']['official_title'].nil?
          flunk 'Please provide correct NCT_ID: <<' + nct_id + '>> Unable to find <<' + db_field + '>> value in the xml'
        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['official_title'] + '>>.'
          @act_offcl_ttle = data_hash_ctgov['clinical_study']['official_title']
        end
        @res = @conn.exec("SELECT official_title FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @exp_offc_ttle = @res.getvalue(0, 0)
        assert_equal(@exp_offc_ttle, @act_offcl_ttle, 'Validating Official Title')
      when 'official title is empty'
        puts 'Verifying: <<' + db_field + '>>.'
        if data_hash_ctgov.has_key?('clinical_study')
          if data_hash_ctgov['clinical_study'].has_key?('official_title')
            assert_not_equal(data_hash_ctgov['clinical_study'].has_key?('official_title'), false, 'Validating official title is empty')
          else
            assert_not_equal(data_hash_ctgov['clinical_study'].has_key?('official_title'), true, 'Validating official title is empty')
          end
        end
      when 'acronym'
        puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['acronym'] + '>>.'
        @res = @conn.exec("SELECT acronym FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        assert_equal(@res.getvalue(0, 0), data_hash_ctgov['clinical_study']['acronym'], 'Validating NCT ID')
      when 'Lead Organization'
        puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['sponsors']['lead_sponsor']['agency'] + '>>.'
        #need to fix this queary
        @res = @conn.exec("SELECT * FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        assert_equal(@res.getvalue(0, 0), data_hash_ctgov['clinical_study']['sponsors']['lead_sponsor']['agency'], 'Validating Lead Organization')
      when 'sponsor'
        puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['sponsors']['lead_sponsor']['agency'] + '>>.'
        @res = @conn.exec("SELECT * FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        assert_equal(@res.getvalue(0, 0), data_hash_ctgov['clinical_study']['sponsors']['lead_sponsor']['agency'], 'Validating Sponsor')
      when 'RO Role'
        puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['sponsors']['lead_sponsor']['agency'] + '>>.'
        @res = @conn.exec("SELECT * FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        assert_equal(@res.getvalue(0, 0), data_hash_ctgov['clinical_study']['sponsors']['lead_sponsor']['agency'], 'Validating RO Role')
      when 'collaborator'
        puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['sponsors']['collaborator'][0]['agency'] + '>>.'
        puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['sponsors']['collaborator'][1]['agency'] + '>>.'
        puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['sponsors']['collaborator'][2]['agency'] + '>>.'
        @res = @conn.exec("SELECT lead_org_id FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        assert_equal(@res.getvalue(0, 0), data_hash_ctgov['clinical_study']['sponsors']['collaborator'][0]['agency'], 'Validating Collaborator')
      when 'Functional Code'
        if data_hash_ctgov['clinical_study']['sponsors']['collaborator'][0]['agency'].nil?
          flunk 'Please provide correct NCT_ID: <<' + nct_id + '>> Unable to find <<' + db_field + '>> value in the xml'
        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['sponsors']['collaborator'][0]['agency'] + '>>.'
          @ct_functional_code = data_hash_ctgov['clinical_study']['sponsors']['collaborator'][0]['agency']
        end
        @res = @conn.exec("SELECT lead_org_id FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        assert_equal(@res.getvalue(0, 0), data_hash_ctgov['clinical_study']['sponsors']['collaborator'][0]['agency'], 'Validating Functional Code')
      when 'Data Monitoring Committee Appointed Indicator'
        if data_hash_ctgov['clinical_study']['oversight_info']['has_dmc'].nil?
          flunk 'Please provide correct NCT_ID: <<' + nct_id + '>> Unable to find <<' + db_field + '>> value in the xml'
        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['oversight_info']['has_dmc'] + '>>.'
          @has_dmc_value = data_hash_ctgov['clinical_study']['oversight_info']['has_dmc']
          if @has_dmc_value.eql?('No')
            @has_dmc_value = 'f'
          elsif @has_dmc_value.eql?('Yes')
            @has_dmc_value = 't'
          end
        end
        @res = @conn.exec("SELECT data_monty_comty_apptn_indicator FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        assert_equal(@res.getvalue(0, 0).to_s, @has_dmc_value.to_s, 'Validating Data Monitoring Committee Appointed Indicator')
      when 'FDA-regulated Drug Product'
        if data_hash_ctgov['clinical_study']['oversight_info']['is_fda_regulated_drug'].nil?

        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['oversight_info']['is_fda_regulated_drug'] + '>>.'
          @has_fda_drug_value = data_hash_ctgov['clinical_study']['oversight_info']['is_fda_regulated_drug']
          if @has_fda_drug_value.eql?('No')
            @has_fda_drug_value = 'false'
          elsif @has_fda_drug_value.eql?('Yes')
            @has_fda_drug_value = 'true'
          end
        end
        headers = {:content_type => 'application/json', :accept => ''}
        @res = @conn.exec("SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        return_db_study_id = @res.getvalue(0, 0).to_s
        @res = @conn.exec("SELECT nci_id FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        return_db_nci_id = @res.getvalue(0, 0).to_s
        @post_endpoint_condition='?study_protocol_id='+return_db_study_id+'&nci_id='+return_db_nci_id+''
        @type = 'STUDY_PROTOCOL_ID_AND_NCI_ID'
        @response, @response_code, @response_body, @id, @nci_id, @trial_id, @study_protocol_id, @response_message = Dataclinicaltrials_api_helper.trigger_get_field_values('GET', 'dataclinicaltrials_ms', ENV['dct_usr'], ENV['dct_pass'], headers, @post_endpoint_condition, @type)
        @response_body.each { |key_value|
          @fda_regulated_drug = key_value['fda_regulated_drug'].to_s
        }
        assert_equal(@fda_regulated_drug.to_s, @has_fda_drug_value.to_s, 'Validating FDA-regulated Drug Product')
      when 'FDA-regulated Device Product'
        if data_hash_ctgov['clinical_study']['oversight_info']['is_fda_regulated_device'].nil?
          flunk 'Please provide correct NCT_ID: <<' + nct_id + '>> Unable to find <<' + db_field + '>> value in the xml'
        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['oversight_info']['is_fda_regulated_device'] + '>>.'
          @has_fda_dvic_value = data_hash_ctgov['clinical_study']['oversight_info']['is_fda_regulated_device']
          if @has_fda_dvic_value.eql?('No')
            @has_fda_dvic_value = 'false'
          elsif @has_fda_dvic_value.eql?('Yes')
            @has_fda_dvic_value = 'true'
          end
        end
        headers = {:content_type => 'application/json', :accept => ''}
        @res = @conn.exec("SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        return_db_study_id = @res.getvalue(0, 0).to_s
        @res = @conn.exec("SELECT nci_id FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        return_db_nci_id = @res.getvalue(0, 0).to_s
        @post_endpoint_condition='?study_protocol_id='+return_db_study_id+'&nci_id='+return_db_nci_id+''
        @type = 'STUDY_PROTOCOL_ID_AND_NCI_ID'
        @response, @response_code, @response_body, @id, @nci_id, @trial_id, @study_protocol_id, @response_message = Dataclinicaltrials_api_helper.trigger_get_field_values('GET', 'dataclinicaltrials_ms', ENV['dct_usr'], ENV['dct_pass'], headers, @post_endpoint_condition, @type)
        @response_body.each { |key_value|
          @fda_regulated_device = key_value['fda_regulated_device'].to_s
        }
        assert_equal(@fda_regulated_device.to_s, @has_fda_dvic_value.to_s, 'Validating FDA-regulated Device Product')
      when 'FDA Approval or Clearance'
        if data_hash_ctgov['clinical_study']['oversight_info']['is_unapproved_device'].nil?
          flunk 'Please provide correct NCT_ID: <<' + nct_id + '>> Unable to find <<' + db_field + '>> value in the xml'
        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['oversight_info']['is_unapproved_device'] + '>>.'
          @has_fda_apprv_value = data_hash_ctgov['clinical_study']['oversight_info']['is_unapproved_device']
          if @has_fda_apprv_value.eql?('No')
            @has_fda_apprv_value = 'false'
          elsif @has_fda_apprv_value.eql?('Yes')
            @has_fda_apprv_value = 'true'
          end
        end
        headers = {:content_type => 'application/json', :accept => ''}
        @res = @conn.exec("SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        return_db_study_id = @res.getvalue(0, 0).to_s
        @res = @conn.exec("SELECT nci_id FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        return_db_nci_id = @res.getvalue(0, 0).to_s
        @post_endpoint_condition='?study_protocol_id='+return_db_study_id+'&nci_id='+return_db_nci_id+''
        @type = 'STUDY_PROTOCOL_ID_AND_NCI_ID'
        @response, @response_code, @response_body, @id, @nci_id, @trial_id, @study_protocol_id, @response_message = Dataclinicaltrials_api_helper.trigger_get_field_values('GET', 'dataclinicaltrials_ms', ENV['dct_usr'], ENV['dct_pass'], headers, @post_endpoint_condition, @type)
        @response_body.each { |key_value|
          @fda_approval_clearance = key_value['post_prior_to_approval'].to_s
        }
        assert_equal(@fda_approval_clearance.to_s, @has_fda_apprv_value.to_s, 'Validating FDA Approval or Clearance')
      when 'Product Exported from the U.S'
        if data_hash_ctgov['clinical_study']['oversight_info']['is_us_export'].nil?
          flunk 'Please provide correct NCT_ID: <<' + nct_id + '>> Unable to find <<' + db_field + '>> value in the xml'
        else
          puts 'Verifying: <<' + data_hash_ctgov['clinical_study']['oversight_info']['is_us_export'] + '>>.'
          @eported_frm_us = data_hash_ctgov['clinical_study']['oversight_info']['is_us_export']
          if @eported_frm_us.eql?('No')
            @eported_frm_us = 'false'
          elsif @eported_frm_us.eql?('Yes')
            @eported_frm_us = 'true'
          end
        end
        headers = {:content_type => 'application/json', :accept => ''}
        @res = @conn.exec("SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        return_db_study_id = @res.getvalue(0, 0).to_s
        @res = @conn.exec("SELECT nci_id FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        return_db_nci_id = @res.getvalue(0, 0).to_s
        @post_endpoint_condition='?study_protocol_id='+return_db_study_id+'&nci_id='+return_db_nci_id+''
        @type = 'STUDY_PROTOCOL_ID_AND_NCI_ID'
        @response, @response_code, @response_body, @id, @nci_id, @trial_id, @study_protocol_id, @response_message = Dataclinicaltrials_api_helper.trigger_get_field_values('GET', 'dataclinicaltrials_ms', ENV['dct_usr'], ENV['dct_pass'], headers, @post_endpoint_condition, @type)
        @response_body.each { |key_value|
          @fda_exported_frm_us = key_value['exported_from_us'].to_s
        }
        assert_equal(@fda_exported_frm_us, @eported_frm_us.to_s, 'Validating Product Exported from the U.S')
      when 'brief_summary'
        #need to compare text block
        brief_s = data_hash_ctgov['clinical_study']['brief_summary']['textblock'].gsub("\n", '')
        @brief_sm = brief_s.gsub(/\s+/, " ").strip
        puts 'Verifying: <<' + @brief_sm + '>>.'
        @res = @conn.exec("SELECT public_description FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        assert_not_nil(@brief_sm, 'Validating brief summary is not null in the json response')
        assert_not_nil(@res, 'Validating brief summary is not null in the db field')
        #assert_equal(@res.getvalue(0, 0).to_s, @brief_sm.to_s, 'Validating brief summary')
      when 'Detailed Description'
        #need to remove some whitespace and next line from the db string
        detal_de = data_hash_ctgov['clinical_study']['detailed_description']['textblock'].gsub("\n", '')
        @detail_desc = detal_de.gsub(/\s+/, " ").strip
        puts 'Verifying: <<' + @detail_desc + '>>.'
        @res = @conn.exec("SELECT scientific_description FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        assert_not_nil(@detail_desc, 'Validating Detailed Description is not null in the json response')
        assert_not_nil(@res, 'Validating Detailed Description is not null in the db field')
        #assert_equal(@res.getvalue(0, 0), @detail_desc, 'Validating Detailed Description')
      when 'In Review'
        in_rvw = data_hash_ctgov['clinical_study']['overall_status']
        @in_rview = in_rvw.to_s
        puts 'Verifying: <<' + @in_rview + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'IN_REVIEW' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('IN_REVIEW')
          @return_db_value = 'Not yet recruiting'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @in_rview, 'Validating In Review Overall status')
      when 'Approved'
        appr = data_hash_ctgov['clinical_study']['overall_status']
        @aprovd = appr.to_s
        puts 'Verifying: <<' + @aprovd + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'APPROVED' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('APPROVED')
          @return_db_value = 'Approved for marketing'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @aprovd, 'Validating Approved Overall status')
      when 'Withdrawn'
        withd = data_hash_ctgov['clinical_study']['overall_status']
        @widndrn = withd.to_s
        puts 'Verifying: <<' + @widndrn + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'WITHDRAWN' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('WITHDRAWN')
          @return_db_value = 'Withdrawn'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @widndrn, 'Validating WITHDRAWN Overall status')
      when 'Active'
        acti = data_hash_ctgov['clinical_study']['overall_status']
        @activ = acti.to_s
        puts 'Verifying: <<' + @activ + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'ACTIVE' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('ACTIVE')
          @return_db_value = 'Available'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @activ, 'Validating ACTIVE/Available trial status')
      when 'Recruiting'
        recrtng = data_hash_ctgov['clinical_study']['overall_status']
        @recruitng = recrtng.to_s
        puts 'Verifying: <<' + @recruitng + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'ACTIVE' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('ACTIVE')
          @return_db_value = 'Recruiting'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @recruitng, 'Validating ACTIVE/Recruiting trial status')
      when 'Enrolling by invitation'
        enrl = data_hash_ctgov['clinical_study']['overall_status']
        @enrlbyinv = enrl.to_s
        puts 'Verifying: <<' + @enrlbyinv + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'ENROLLING_BY_INVITATION' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('ENROLLING_BY_INVITATION')
          @return_db_value = 'Enrolling by invitation'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @enrlbyinv, 'Validating Enrolling by invitation trial status')
      when 'Closed to Accrual'
        clstoe = data_hash_ctgov['clinical_study']['overall_status']
        @clos_to_acc = clstoe.to_s
        puts 'Verifying: <<' + @clos_to_acc + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'CLOSED_TO_ACCRUAL' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('CLOSED_TO_ACCRUAL')
          @return_db_value = 'Active, not recruiting'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @clos_to_acc, 'Validating Closed to Accrual trial status')
      when 'Closed to Accrual and Intervention'
        clstoanintervn = data_hash_ctgov['clinical_study']['overall_status']
        @clos_to_acc_intrvntn = clstoanintervn.to_s
        puts 'Verifying: <<' + @clos_to_acc_intrvntn + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'CLOSED_TO_ACCRUAL_AND_INTERVENTION' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('CLOSED_TO_ACCRUAL_AND_INTERVENTION')
          @return_db_value = 'No longer available'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @clos_to_acc_intrvntn, 'Validating Closed to Accrual and Intervention trial status')
      when 'Temporarily Closed to Accrual and Intervention'
        tmpclstoanintervn = data_hash_ctgov['clinical_study']['overall_status']
        @tmp_clos_to_acc_intrvntn = tmpclstoanintervn.to_s
        puts 'Verifying: <<' + @tmp_clos_to_acc_intrvntn + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'TEMPORARILY_CLOSED_TO_ACCRUAL_AND_INTERVENTION' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('TEMPORARILY_CLOSED_TO_ACCRUAL_AND_INTERVENTION')
          @return_db_value = 'Suspended'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @tmp_clos_to_acc_intrvntn, 'Validating Temporarily Closed to Accrual and Intervention trial status')
      when 'Completed'
        complt = data_hash_ctgov['clinical_study']['overall_status']
        @complet = complt.to_s
        puts 'Verifying: <<' + @complet + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'COMPLETED' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('COMPLETED')
          @return_db_value = 'Completed'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @complet, 'Validating Completed trial status')
      when 'Administratively Complete'
        admincomplt = data_hash_ctgov['clinical_study']['overall_status']
        @admintrvly_complet = admincomplt.to_s
        puts 'Verifying: <<' + @admintrvly_complet + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'ADMINISTRATIVELY_COMPLETE' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('ADMINISTRATIVELY_COMPLETE')
          @return_db_value = 'Terminated'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @admintrvly_complet, 'Validating Administratively Complete trial status')
      when 'Temporarily not available'
        tmpnotavail = data_hash_ctgov['clinical_study']['overall_status']
        @tmp_not_avail = tmpnotavail.to_s
        puts 'Verifying: <<' + @tmp_not_avail + '>>.'
        @res = @conn.exec("SELECT status_code FROM study_recruitment_status WHERE status_code = 'TEMPORARILY_CLOSED_TO_ACCRUAL_AND_INTERVENTION' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        @return_db_value = @res.getvalue(0, 0).to_s
        if @return_db_value.eql?('TEMPORARILY_CLOSED_TO_ACCRUAL_AND_INTERVENTION')
          @return_db_value = 'Temporarily not available'
        else
          @return_db_value
        end
        assert_equal(@return_db_value, @tmp_not_avail, 'Validating Temporarily Closed to Accrual and Intervention/Temporarily not available trial status')
      else
        flunk 'Please provide correct db_field. Provided db_filed <<' + db_field + '>> does not exist'
    end
    @conn.close if @conn
  end

  def self.verify_xml_json_element_with_db(db_field, nct_id, data_hash_ctgov)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    case db_field
      when 'Trial Start Date', 'Trial Start Date (DD should be 01)'
        trailstartdate = data_hash_ctgov['clinical_study']['start_date']
        @trial_start_date = trailstartdate.to_s
        puts 'Verifying: <<' + @trial_start_date + '>>.'
        @res = @conn.exec("SELECT start_date FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_rslt = @res.getvalue(0, 0)
        if db_field.eql?('Trial Start Date (DD should be 01)')
          assert_equal(@trial_start_date.include?(','), false, 'Validating Date format as trial status')
        end
        if @trial_start_date.include?(',')
          t = Time.parse(@return_db_rslt)
          @tm = t.strftime("%B %e, %Y")
          @rm_ext_spce = @tm.split.join(" ")
          @return_db_value = @rm_ext_spce.to_s
        else
          t = Time.parse(@return_db_rslt)
          @tm = t.strftime("%B %Y")
          @return_db_value = @tm.to_s
        end
        assert_equal(@return_db_value, @trial_start_date, 'Validating Start Date trial status')
      when 'Trial Start Date option'
        @data_sml = @data_xml_ctgov
        @data_sml.search('clinical_study').each do |start_date_tag|
          #start_date_tag_xml = start_date_tag.at('start_date').text
          start_date_type_xml = start_date_tag.at('start_date').get_attribute "type"
          if start_date_type_xml.nil?
            @start_date_type_val = 'ACTUAL'
          else
            @start_date_type_val = start_date_type_xml.upcase
          end
        end
        trailstartdateoption = @start_date_type_val
        @trial_start_date_option = trailstartdateoption.to_s
        puts 'Verifying: <<' + @trial_start_date_option + '>>.'
        @res = @conn.exec("SELECT start_date_type_code FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_value = @res.getvalue(0, 0).to_s
        assert_equal(@return_db_value, @trial_start_date_option, 'Validating Start Date Option trial status')
      when 'Completion Date', 'Completion Date (DD should be 01)'
        trailcompletiondate = data_hash_ctgov['clinical_study']['completion_date']
        @trial_comp_date = trailcompletiondate.to_s
        puts 'Verifying: <<' + @trial_comp_date + '>>.'
        @res = @conn.exec("SELECT completion_date FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_rslt = @res.getvalue(0, 0)
        if @trial_comp_date.include?(',')
          t = Time.parse(@return_db_rslt)
          @tm = t.strftime("%B %e, %Y")
          @rm_ext_spce = @tm.split.join(" ")
          @return_db_value = @rm_ext_spce.to_s
        else
          t = Time.parse(@return_db_rslt)
          @tm = t.strftime("%B %Y")
          @return_db_value = @tm.to_s
        end
        assert_equal(@return_db_value, @trial_comp_date, 'Validating Completion Date trial status')
      when 'Completion Date option'
        @data_sml = @data_xml_ctgov
        @data_sml.search('clinical_study').each do |comp_date_tag|
          comp_date_type_xml = comp_date_tag.at('completion_date').get_attribute "type"
          if comp_date_type_xml.nil?
            @comp_date_type_val = 'ACTUAL'
          else
            @comp_date_type_val = comp_date_type_xml.upcase
          end
        end
        compstartdateoption = @comp_date_type_val
        @trial_comp_date_option = compstartdateoption.to_s
        puts 'Verifying: <<' + @trial_comp_date_option + '>>.'
        @res = @conn.exec("SELECT completion_date_type_code FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_value = @res.getvalue(0, 0).to_s
        assert_equal(@return_db_value, @trial_comp_date_option, 'Validating Completion Date Option trial status')
      when 'Primary Completion Date', 'Primary Completion Date (DD should be 01)'
        trailprimarycompletiondate = data_hash_ctgov['clinical_study']['primary_completion_date']
        @trial_primary_comp_date = trailprimarycompletiondate.to_s
        puts 'Verifying: <<' + @trial_primary_comp_date + '>>.'
        @res = @conn.exec("SELECT pri_compl_date FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_rslt = @res.getvalue(0, 0)
        if @trial_primary_comp_date.include?(',')
          t = Time.parse(@return_db_rslt)
          @tm = t.strftime("%B %e, %Y")
          @rm_ext_spce = @tm.split.join(" ")
          @return_db_value = @rm_ext_spce.to_s
        else
          t = Time.parse(@return_db_rslt)
          @tm = t.strftime("%B %Y")
          @return_db_value = @tm.to_s
        end
        assert_equal(@return_db_value, @trial_primary_comp_date, 'Validating Primary Completion Date trial status')
      when 'Primary Completion Date option'
        @data_sml = @data_xml_ctgov
        @data_sml.search('clinical_study').each do |prmy_comp_date_tag|
          prmy_comp_date_type_xml = prmy_comp_date_tag.at('primary_completion_date').get_attribute "type"
          if prmy_comp_date_type_xml.nil?
            @prmry_comp_date_type_val = 'ACTUAL'
          else
            @prmry_comp_date_type_val = prmy_comp_date_type_xml.upcase
          end
        end
        prmrycompdateoption = @prmry_comp_date_type_val
        @trial_primary_comp_date_option = prmrycompdateoption.to_s
        puts 'Verifying: <<' + @trial_primary_comp_date_option + '>>.'
        @res = @conn.exec("SELECT pri_compl_date_type_code FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_value = @res.getvalue(0, 0).to_s
        assert_equal(@return_db_value, @trial_primary_comp_date_option, 'Validating Primary Completion Date Option trial status')
      else
        flunk 'Please provide correct db_field. Provided db_filed <<' + db_field + '>> does not exist'
    end
    @conn.close if @conn
  end

  def self.verify_phase(db_field, nct_id, data_hash_ctgov)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    case db_field
      when 'Early Phase 1', 'I', 'I/II', 'II', 'II/III', 'III', 'IV', 'NA'
        @data_sml = @data_xml_ctgov
        @data_sml.search('clinical_study').each do |phase_tag|
          @phase_val_xml = phase_tag.at('phase').text
        end
        @phase_option = @phase_val_xml.to_s
        assert_equal(@phase_option.nil?, false, 'Validating phase is not empty')
        if @phase_val_xml.eql?('Phase 1')
          @phase_option = 'I'
        elsif @phase_val_xml.eql?('Phase 1/Phase 2')
          @phase_option = 'I_II'
        elsif @phase_val_xml.eql?('Phase 2')
          @phase_option = 'II'
        elsif @phase_val_xml.eql?('Phase 2/Phase 3')
          @phase_option = 'II_III'
        elsif @phase_val_xml.eql?('Phase 3')
          @phase_option = 'III'
        elsif @phase_val_xml.eql?('Phase 4')
          @phase_option = 'IV'
        elsif @phase_val_xml.eql?('N/A')
          @phase_option = 'NA'
        else
          @phase_option = @phase_val_xml
        end
        @trial_phase_option = @phase_option.to_s
        puts 'Verifying: <<' + @trial_phase_option + '>>.'
        @res = @conn.exec("SELECT phase_code FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_value = @res.getvalue(0, 0).to_s
        assert_equal(@return_db_value, @trial_phase_option, 'Validating Trial Phase option')
      else
        flunk 'Please provide correct db_field. Provided db_filed <<' + db_field + '>> does not exist'
    end
    @conn.close if @conn
  end

  def self.verify_trial_type(db_field, nct_id, data_hash_ctgov)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    @pass_nct_id = nct_id
    case db_field
      when 'Interventional Study', 'Non-Interventional Study'
        @expanded_access = @data_xml_ctgov
        @expanded_access.search('clinical_study').each do |expanded_access_tag|
          @expnded_access_val_xml = expanded_access_tag.at('study_type').text
        end
        @expndd_accss_option = @expnded_access_val_xml.to_s
        assert_equal(@expndd_accss_option.nil?, false, 'Validating CTRP Study Type is not empty')
        if @expnded_access_val_xml.eql?('Expanded Access')
          @expndd_accss_option = 'InterventionalStudyProtocol'
        elsif @expnded_access_val_xml.eql?('Interventional')
          @expndd_accss_option = 'InterventionalStudyProtocol'
        elsif @expnded_access_val_xml.eql?('Observational')
          @expndd_accss_option = 'NonInterventionalStudyProtocol'
        elsif @expnded_access_val_xml.eql?('Observational [Patient Registry]')
          @expndd_accss_option = 'NonInterventionalStudyProtocol'
        else
          @expndd_accss_option = @expnded_access_val_xml
        end
        @trial_type_option = @expndd_accss_option.to_s
        puts 'Verifying: <<' + @trial_type_option + '>>.'
        @res = @conn.exec("SELECT study_protocol_type FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_value = @res.getvalue(0, 0).to_s
        assert_equal(@return_db_value, @trial_type_option, 'Validating Trial Type option')
      else
        flunk 'Please provide correct db_field. Provided db_filed <<' + db_field + '>> does not exist'
    end
    @conn.close if @conn
  end

  def self.verify_expanded_access(arg1)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    puts 'Verifying Expanded Access Value: <<' + arg1 + '>>.'
    @res = @conn.exec("SELECT expd_access_indidicator FROM study_protocol WHERE nct_id = '" + @pass_nct_id + "' AND status_code = 'ACTIVE'")
    @return_db_value = @res.getvalue(0, 0).to_s
    @conn.close if @conn
    if @return_db_value.eql?('t')
      @return_db_value = 'True'
    elsif @return_db_value.eql?('f')
      @return_db_value = 'False'
    end
    if arg1.nil?
      flunk 'Please provide expanded access value as Yes or No'
    else
      if arg1.eql?('Yes')
        @expndd_accss_indi = 'True'
      elsif arg1.eql?('No')
        @expndd_accss_indi = 'False'
      else
        flunk 'Please provide correct expanded access indicator value. Provided expanded access indicator value <<' + arg1 + '>> does not exist'
      end
    end
    @expn_accss_indicator = @expndd_accss_indi.to_s
    assert_equal(@return_db_value, @expn_accss_indicator, 'Validating Expanded Access Indicator option')
    @conn.close if @conn
  end

  def self.verify_allocation(db_field, nct_id, data_hash_ctgov)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    case db_field
      when 'Randomized Controlled Trial', 'Non-Randomized Trial'
        trail_allocation = data_hash_ctgov['clinical_study']['study_design_info']['allocation']
        @trial_study_allocation = trail_allocation.to_s
        @randomized_trial = @data_xml_ctgov
        @randomized_trial.search('//study_design_info').each do |allocation_tag|
          @randomized_trial_val_xml = allocation_tag.at('allocation').text
        end
        @allocation_option = @randomized_trial_val_xml.to_s
        assert_equal(@allocation_option.nil?, false, 'Validating CTRP Study Allocation is not empty')
        if @randomized_trial_val_xml.eql?('Randomized')
          @allocation_option = 'RANDOMIZED_CONTROLLED_TRIAL'
        elsif @randomized_trial_val_xml.eql?('Non-Randomized')
          @allocation_option = 'NON_RANDOMIZED_TRIAL'
        else
          @allocation_option = @randomized_trial_val_xml
        end
        @trial_allocation_option = @allocation_option.to_s
        puts 'Verifying: <<' + @trial_allocation_option + '>>.'
        @res = @conn.exec("SELECT allocation_code FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_value = @res.getvalue(0, 0).to_s
        assert_equal(@return_db_value, @trial_allocation_option, 'Validating Trial Study Allocation option')
      else
        flunk 'Please provide correct db_field. Provided db_filed <<' + db_field + '>> does not exist'
    end
    @conn.close if @conn
  end

  def self.verify_interventional_mdl(db_field, nct_id, data_hash_ctgov)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    case db_field
      when 'Single Group', 'Parallel', 'Cross-over', 'Factorial', 'Sequential'
        trail_interventional = data_hash_ctgov['clinical_study']['study_design_info']['intervention_model']
        @trial_intrvntn_mdl = trail_interventional.to_s
        @interventional_mdl_trial = @data_xml_ctgov
        @interventional_mdl_trial.search('//study_design_info').each do |interventional_tag|
          @intvnal_mdl_trial_val_xml = interventional_tag.at('intervention_model').text
        end
        @interventional_mdl_option = @intvnal_mdl_trial_val_xml.to_s
        assert_equal(@interventional_mdl_option.nil?, false, 'Validating CTRP Study Interventional Model is not empty')
        if @intvnal_mdl_trial_val_xml.eql?('Single Group Assignment')
          @interventional_mdl_option = 'SINGLE_GROUP'
        elsif @intvnal_mdl_trial_val_xml.eql?('Parallel Assignment')
          @interventional_mdl_option = 'PARALLEL'
        elsif @intvnal_mdl_trial_val_xml.eql?('Crossover Assignment')
          @interventional_mdl_option = 'CROSSOVER'
        elsif @intvnal_mdl_trial_val_xml.eql?('Factorial Assignment')
          @interventional_mdl_option = 'FACTORIAL'
        elsif @intvnal_mdl_trial_val_xml.eql?('Sequential Assignment')
          @interventional_mdl_option = 'SEQUENTIAL_ASSIGNMENT'
        else
          @interventional_mdl_option = @intvnal_mdl_trial_val_xml
        end
        @trial_allocation_option = @interventional_mdl_option.to_s
        puts 'Verifying: <<' + @trial_allocation_option + '>>.'
        @res = @conn.exec("SELECT design_configuration_code FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_value = @res.getvalue(0, 0).to_s
        assert_equal(@return_db_value, @trial_allocation_option, 'Validating Trial Interventional Model option')
      else
        flunk 'Please provide correct db_field. Provided db_filed <<' + db_field + '>> does not exist'
    end
    @conn.close if @conn
  end

  def self.verify_masking(db_field, nct_id, data_hash_ctgov)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    case db_field
      when 'No masking', 'Participant', 'Investigator', 'Care Provider', 'Outcomes Assessor'
        mskng_trl = data_hash_ctgov['clinical_study']['study_design_info']['masking']
        @mskng_trial_jsn = mskng_trl.to_s
        @mskng_trl_xml = @data_xml_ctgov
        @mskng_trl_xml.search('//study_design_info').each do |interventional_tag|
          @mskng_trial_val_xml = interventional_tag.at('masking').text
        end
        @masking_option = @mskng_trial_val_xml.to_s
        if @mskng_trial_val_xml.eql?('No masking')
          @masking_option = 'true'
          assert_equal(@masking_option.nil?, false, 'Validating CTRP Masking is not empty')
          headers = {:content_type => 'application/json', :accept => ''}
          @res = @conn.exec("SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
          return_db_study_id = @res.getvalue(0, 0).to_s
          @res = @conn.exec("SELECT nci_id FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
          return_db_nci_id = @res.getvalue(0, 0).to_s
          @post_endpoint_condition='?study_protocol_id='+return_db_study_id+'&nci_id='+return_db_nci_id+''
          @type = 'STUDY_PROTOCOL_ID_AND_NCI_ID'
          @response, @response_code, @response_body, @id, @nci_id, @trial_id, @study_protocol_id, @response_message = Dataclinicaltrials_api_helper.trigger_get_field_values('GET', 'dataclinicaltrials_ms', ENV['dct_usr'], ENV['dct_pass'], headers, @post_endpoint_condition, @type)
          @response_body.each { |key_value|
            @no_masking = key_value['no_masking'].to_s
          }
        elsif @mskng_trial_val_xml.eql?('Participant, Investigator, Outcomes Assessor')
          @masking_option = 'Participant'
        elsif @mskng_trial_val_xml.eql?('Investigator')
          @masking_option = 'Investigator'
        elsif @mskng_trial_val_xml.eql?('Care Provider')
          @masking_option = 'Care Provider'
        elsif @mskng_trial_val_xml.eql?('Outcomes Assessor')
          @masking_option = 'Outcomes Assessor'
        else
          @masking_option = @mskng_trial_val_xml
        end
        @trial_msking_exp = @masking_option.to_s
        puts 'Verifying CTRP Masking: <<' + @trial_msking_exp + '>>.'
        if @no_masking.nil?
          @res = @conn.exec("SELECT allocation_code FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
          @return_db_value = @res.getvalue(0, 0).to_s
        elsif @no_masking.eql?('true')
          @return_db_value = @no_masking
        elsif @no_masking.eql?('false')
          @return_db_value = @no_masking
        end
        assert_equal(@return_db_value, @trial_msking_exp, 'Validating CTRP Masking option')
      else
        flunk 'Please provide correct db_field. Provided db_filed <<' + db_field + '>> does not exist'
    end
    @conn.close if @conn
  end

  def self.verify_primary_purpose(db_field, nct_id, data_hash_ctgov)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    case db_field
      when 'Basic Science', 'Diagnostic', 'Health Services Research', 'Prevention', 'Screening', 'Supportive Care', 'Treatment', 'Device Feasibility', 'Other'
        prmry_purps_trl = data_hash_ctgov['clinical_study']['study_design_info']['primary_purpose']
        @pr_ps_trial_jsn = prmry_purps_trl.to_s
        @pr_ps_trl_xml = @data_xml_ctgov
        @pr_ps_trl_xml.search('//study_design_info').each do |interventional_tag|
          @pr_ps_tral_val_xml = interventional_tag.at('primary_purpose').text
        end
        @prmry_pps_option = @pr_ps_tral_val_xml.to_s
        if @pr_ps_tral_val_xml.eql?('Basic Science') && db_field.eql?('Basic Science')
          @prmry_pps_option = 'BASIC_SCIENCE'
        elsif @pr_ps_tral_val_xml.eql?('Diagnostic') && db_field.eql?('Diagnostic')
          @prmry_pps_option = 'DIAGNOSTIC'
        elsif @pr_ps_tral_val_xml.eql?('Health Services Research') && db_field.eql?('Health Services Research')
          @prmry_pps_option = 'HEALTH_SERVICES_RESEARCH'
        elsif @pr_ps_tral_val_xml.eql?('Prevention') && db_field.eql?('Prevention')
          @prmry_pps_option = 'PREVENTION'
        elsif @pr_ps_tral_val_xml.eql?('Screening') && db_field.eql?('Screening')
          @prmry_pps_option = 'SCREENING'
        elsif @pr_ps_tral_val_xml.eql?('Supportive Care') && db_field.eql?('Supportive Care')
          @prmry_pps_option = 'SUPPORTIVE_CARE'
        elsif @pr_ps_tral_val_xml.eql?('Treatment') && db_field.eql?('Treatment')
          @prmry_pps_option = 'TREATMENT'
        elsif @pr_ps_tral_val_xml.eql?('Device Feasibility') && db_field.eql?('Device Feasibility')
          @prmry_pps_option = 'DEVICE'
        elsif @pr_ps_tral_val_xml.eql?('Other') && db_field.eql?('Other')
          @prmry_pps_option = 'OTHER'
        else
          @prmry_pps_option = @pr_ps_tral_val_xml
        end
        @trial_msking_exp = @prmry_pps_option.to_s
        puts 'Verifying CTRP Primary Purpose: <<' + @trial_msking_exp + '>>.'
        @res = @conn.exec("SELECT primary_purpose_code FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE'")
        @return_db_value = @res.getvalue(0, 0).to_s
        assert_equal(@return_db_value, @trial_msking_exp, 'Validating CTRP Primary Purpose option')
      else
        flunk 'Please provide correct db_field. Provided db_filed <<' + db_field + '>> does not exist'
    end
    @conn.close if @conn
  end

  def self.verify_outcome_measures(db_field, nct_id, data_hash_ctgov)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    case db_field
      when 'Outcome Measure Type = “PRIMARY”'
        puts 'Verifying Outcome Measures: <<' + db_field + '>>.'
        @indicator_booln = 'true'
        primary_measure = data_hash_ctgov['clinical_study']['primary_outcome']['measure']
        time_frame_measure = data_hash_ctgov['clinical_study']['primary_outcome']['time_frame']
        description_measure = data_hash_ctgov['clinical_study']['primary_outcome']['description']
        res = @conn.exec("SELECT name FROM study_outcome_measure WHERE primary_indicator = '" + @indicator_booln + "' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        primary_mesrs_return_db_value = res.getvalue(0, 0).to_s
        res = @conn.exec("SELECT timeframe FROM study_outcome_measure WHERE primary_indicator = '" + @indicator_booln + "' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        time_frame_return_db_value = res.getvalue(0, 0).to_s
        res = @conn.exec("SELECT description FROM study_outcome_measure WHERE primary_indicator = '" + @indicator_booln + "' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        desc_return_db_value = res.getvalue(0, 0).to_s
        assert_equal(primary_mesrs_return_db_value, primary_measure, 'Validating CTRP Primary Outcome Measures name')
        assert_equal(time_frame_return_db_value, time_frame_measure, 'Validating CTRP Primary Outcome Measures time frame')
        assert_equal(desc_return_db_value, description_measure, 'Validating CTRP Primary Outcome Measures description')
      when 'Outcome Measure Type = “SECONDARY”'
        puts 'Verifying Outcome Measures: <<' + db_field + '>>.'
        @indicator_booln = 'true'
        primary_measure = data_hash_ctgov['clinical_study']['secondary_outcome'][0]['measure']
        time_frame_measure = data_hash_ctgov['clinical_study']['secondary_outcome'][0]['time_frame']
        description_measure = data_hash_ctgov['clinical_study']['secondary_outcome'][0]['description']
        res = @conn.exec("SELECT name FROM study_outcome_measure WHERE primary_indicator = '" + @indicator_booln + "' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        primary_mesrs_return_db_value = res.getvalue(0, 0).to_s
        res = @conn.exec("SELECT timeframe FROM study_outcome_measure WHERE primary_indicator = '" + @indicator_booln + "' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        time_frame_return_db_value = res.getvalue(0, 0).to_s
        res = @conn.exec("SELECT description FROM study_outcome_measure WHERE primary_indicator = '" + @indicator_booln + "' AND study_protocol_identifier in (SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')")
        desc_return_db_value = res.getvalue(0, 0).to_s
        assert_equal(primary_mesrs_return_db_value, primary_measure, 'Validating CTRP Primary Outcome Measures name')
        assert_equal(time_frame_return_db_value, time_frame_measure, 'Validating CTRP Primary Outcome Measures time frame')
        assert_equal(desc_return_db_value, description_measure, 'Validating CTRP Primary Outcome Measures description')
      else
        flunk 'Please provide correct db_field. Provided db_filed <<' + db_field + '>> does not exist'
    end
    @conn.close if @conn
  end

  def self.verify_maximum_age(nct_id, expected_input, expected_output)
    begin
      @conn = PGconn.connect(:host => ENV['db_hostname'], :port => ENV['db_port'], :dbname => ENV['db_name'], :user => ENV['db_user'], :password => ENV['db_pass'])
    rescue PGconn::Error => e
      @conn = e.message
    end
    unless expected_input.nil?
      ctrp_query = "SELECT max_value, max_unit from planned_eligibility_criterion where identifier in " +
          "(SELECT identifier from planned_activity where study_protocol_identifier in " +
          "(SELECT identifier FROM study_protocol WHERE nct_id = '" + nct_id + "' AND status_code = 'ACTIVE')) " +
          "and planned_eligibility_criterion.criterion_name = 'AGE'"
      ctrp_max_age      = @conn.exec(ctrp_query).getvalue(0,0)
      ctrp_max_age_unit = @conn.exec(ctrp_query).getvalue(0,1)
      if expected_input == "N/A"
        assert_equal("999 Years", expected_output)
      else
        assert_equal(expected_input, expected_output)
      end
      assert_equal("#{ctrp_max_age} #{ctrp_max_age_unit}", expected_output)
    end
    @conn.close if @conn
  end

end


