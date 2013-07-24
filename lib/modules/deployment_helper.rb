module DeploymentHelper
  require 'hashie'
  require 'Json'
  include GithubHelper
  include RightscaleHelper
  include DnsmadeeasyHelper

  def validate_request(request)
    request_content = Hashie::Mash.new(request)
    begin
      valid_deployment_profile?(request_content.profile_id)
      valid_repos?(request_content.profile_id,request_content.repos)
      valid_inputs?(request_content.profile_id,request_content.inputs)
    rescue => error
      raise error
    end
    request_content
  end

  def perform_deployment(deployment_info)
    deployment_details = {}
    profile_id = deployment_info.profile_id
    repo_info = deployment_info.repos
    input_info = deployment_info.inputs
    dns_info = deployment_info.subdomain
    deployment_details[:dns_info] = update_dns_entries(profile_id,dns_info)
    deployment_details[:tag_info] = perform_tagging(profile_id,repo_info)
    #update_rightscale_inputs(profile_id,input_info)
    deployment_details[:rs_info] = launch_array_instances(profile_id)
    deployment_details
  end

  private

  def update_rightscale_inputs(profile_id, input_info)
    deployment_profile = DeploymentProfile.find_by_profile_id(profile_id)
    rs_input_hash = prepare_input_hash(deployment_profile.inputs,input_info)
    rs_client = Rightscale.new(deployment_profile.rs_account)
    rs_client.update_array_inputs(deployment_profile.rs_array,rs_input_hash)
  end

  def launch_array_instances(profile_id)
    rs_results = {}
    #deployment_profile = DeploymentProfile.find_by_profile_id(profile_id)
    #rs_client = Rightscale.new(deployment_profile.rs_account)
    #results = rs_client.launch_array_instances(deployment_profile.rs_array)
    rs_results[:instance_href] = 'https://my.rightscale.com/acct/44210/clouds/1/ec2_instances/10369846001' #results['location']
    rs_results
  end

  def prepare_input_hash(stored_inputs,request_inputs)
    input_hash = {}
    request_inputs.each do |input|
      rs_name = (stored_inputs.detect {|i| i.human_name == input[0]}).rs_name
      input_hash[rs_name] = "text:#{input[1]}"
    end
    input_hash
  end

  def perform_tagging(profile_id,repo_info)
    repos = DeploymentProfile.find_by_profile_id(profile_id).repos
    process_github_repos(repo_info,repos)
  end

  def update_dns_entries(profile_id,sub_domain)
    profile_domain = DeploymentProfile.find_by_profile_id(profile_id).domain
    dns_client = Dns.new
    domain = dns_client.domain(profile_domain)
    domain.create_subdomain(sub_domain)
  end

  def valid_deployment_profile?(profile_id)
    if DeploymentProfile.exists?(:profile_id => profile_id)
      true
    else
      raise("Deployment profile #{profile_id} could not be found")
    end
  end

  def valid_repos?(profile_id,repos)
    allowed_profile_repos = DeploymentProfile.find_by_profile_id(profile_id).repos.pluck(:repo_name)
    invalid_repos = repos.keys.select { |repo| !allowed_profile_repos.include?(repo) }
    invalid_repos.blank? ? true : raise("Invalid repo: #{invalid_repos} was provided for deployment profile")
  end

  def valid_inputs?(profile_id,inputs)
    allowed_profile_inputs = DeploymentProfile.find_by_profile_id(profile_id).inputs.pluck(:human_name)
    invalid_inputs = inputs.keys.select { |input| !allowed_profile_inputs.include?(input) }
    invalid_inputs.blank? ? true : raise("Invalid input #{invalid_inputs} was provided for deployment profile")
  end


end