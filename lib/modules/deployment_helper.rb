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
      valid_repos?(request_content.profile_id, request_content.repos)
      valid_inputs?(request_content.profile_id, request_content.inputs)
    rescue => error
      raise error
    end
    request_content
  end

  def perform_deployment(deployment_info)
    begin
      deployment_details = {}
      repo_info = deployment_info.repos
      input_info = deployment_info.inputs
      dns_info = deployment_info.subdomain
      deployment_details[:dns_info] = update_dns_entries(dns_info)
      deployment_details[:tag_info] = perform_tagging(repo_info)
      update_rightscale_inputs(input_info, deployment_details[:tag_info])
      deployment_details[:rs_info] = launch_array_instances
      deployment_details
    rescue => e
      raise e
    end
  end

  private
  def update_rightscale_inputs(input_info, tag_info)
    deployment_profile = self.deployment_profile
    rs_input_hash = prepare_input_hash(deployment_profile.inputs, input_info, tag_info)
    rs_client = Rightscale.new(deployment_profile.rs_account)
    rs_client.update_array_inputs(deployment_profile.rs_array, rs_input_hash)
  end

  def launch_array_instances
    rs_client = Rightscale.new(self.deployment_profile.rs_account)
    #rs_client.launch_array_instances(deployment_profile.rs_array)
    rs_client::RsLaunchResult.new('https://my.rightscale.com/acct/44210/clouds/1/ec2_instances/10369846001') #just for testing
  end

  def prepare_input_hash(stored_inputs, request_inputs, tag_info)
    input_hash = {}
    request_inputs.each do |input|
      rs_name = (stored_inputs.detect { |i| i.human_name == input[0] }).rs_name
      input_hash[rs_name] = "text:#{input[1]}"
    end
    add_default_tags(input_hash, tag_info) #Todo insert tag portion of hash into this var. maybe do it in another method
  end

  def add_default_tags(input_hash, tag_info)
    added_inputs = {}
    default_inputs = self.deployment_profile.inputs.defaults
    default_values = { :app_tag => tag_info[0].tag, :deploy_id => self.deployment_guid }
    default_inputs.each do |default_input|
      key = default_input.input_type.downcase.to_sym
      added_inputs[default_input.rs_name] = "text:#{default_values[key]}"
    end
    input_hash.merge(added_inputs)
  end

  def perform_tagging(repo_info)
    repos = self.deployment_profile.repos
    process_github_repos(repo_info, repos)
  end

  def update_dns_entries(sub_domain)
    profile_domain = self.deployment_profile.domain
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

  def valid_repos?(profile_id, repos)
    allowed_profile_repos = DeploymentProfile.find_by_profile_id(profile_id).repos.pluck(:repo_name)
    invalid_repos = repos.keys.select { |repo| !allowed_profile_repos.include?(repo) }
    invalid_repos.blank? ? true : raise("Invalid repo: #{invalid_repos} was provided for deployment profile")
  end

  def valid_inputs?(profile_id, inputs)
    allowed_profile_inputs = DeploymentProfile.find_by_profile_id(profile_id).inputs.pluck(:human_name)
    invalid_inputs = inputs.keys.select { |input| !allowed_profile_inputs.include?(input) }
    invalid_inputs.blank? ? true : raise("Invalid input #{invalid_inputs} was provided for deployment profile")
  end


end