module DeploymentHelper
  require 'hashie'
  require 'Json'
  include GithubHelper
  include RightscaleHelper
  include DnsmadeeasyHelper

  #When request come in I would like to know if they contain all the needed
  #bits of information to properly process it
  #This method will call 3 methods to do the following
  #check if the deployment profile id provided exists in the system
  #check if the repo names provided for the deployment profile are valid
  #check if the inputs provided for the deployment profile are valid
  # @param [Hash] request
  # @return [Hashie]
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

  #this is the main driver method for the deployment
  #deployment info is a hasiemash of the json sent by the requestor
  #each functional area of the deployment is called with information needed to perform deployment
  # @param [Hashie] deployment_info
  # @return [Hash]
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
  # Prepare inputs for RS api call
  # create new rs client for the specified account
  # update inputs in given array with the prepared hash
  # @param [Hash] input_info
  # @param [Array] tag_info
  # @return [NilClass]
  def update_rightscale_inputs(input_info, tag_info)
    deployment_profile = self.deployment_profile
    rs_input_hash = prepare_input_hash(deployment_profile.inputs, input_info, tag_info)
    rs_client = Rightscale.new(deployment_profile.rs_account)
    rs_client.update_array_inputs(deployment_profile.rs_array, rs_input_hash)
  end

  # launch single machine in specified array that's been updated
  # @return [RSLaunchResult]
  def launch_array_instances
    rs_client = Rightscale.new(self.deployment_profile.rs_account)
    #rs_client.launch_array_instances(deployment_profile.rs_array)
    rs_client::RsLaunchResult.new('https://my.rightscale.com/acct/44210/clouds/1/ec2_instances/10369846001') #just for testing
  end

  # We want to match inputs that we have stored with inputs provided by requestor
  # We then want to get that inputs fully qualified rs name
  # we then want the  full name to be matched up with the value provided by the requestor
  # We then want to add our extra inputs such as deployment id to the hash
  # @param [Array] stored_inputs Active record objects
  # @param [Hash] request_inputs
  # @param [Array] tag_info
  def prepare_input_hash(stored_inputs, request_inputs, tag_info)
    input_hash = {}
    request_inputs.each do |input|
      rs_name = (stored_inputs.detect { |i| i.human_name == input[0] }).rs_name
      input_hash[rs_name] = "text:#{input[1]}"
    end
    add_default_tags(input_hash, tag_info)
  end

  # We want to merge the hash of requestor supplied values with system provided values
  # We want to add the deployment id as well as the tag info to the hash
  # @param [Hash] input_hash
  # @param [Array] tag_info
  # @return [Hash]
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

  # we want to tag the github repos with the next available tag
  # @param [Hash] repo_info
  # @return [Array]
  def perform_tagging(repo_info)
    repos = self.deployment_profile.repos
    process_github_repos(repo_info, repos)
  end

  # we want to create a new subdomain based on the data provided by the requestor
  # @param [String] sub_domain
  def update_dns_entries(sub_domain)
    profile_domain = self.deployment_profile.domain
    dns_client = Dns.new
    domain = dns_client.domain(profile_domain)
    domain.create_subdomain(sub_domain)
  end

  # we want to check if the provided profile is defined in the system
  # @param [String] profile_id
  def valid_deployment_profile?(profile_id)
    if DeploymentProfile.exists?(:profile_id => profile_id)
      true
    else
      raise("Deployment profile #{profile_id} could not be found")
    end
  end

  # we want to determine if all of the repos provided in request are part of the given profile
  # @param [String] profile_id
  # @param [Hash] repos
  def valid_repos?(profile_id, repos)
    allowed_profile_repos = DeploymentProfile.find_by_profile_id(profile_id).repos.pluck(:repo_name)
    invalid_repos = repos.keys.select { |repo| !allowed_profile_repos.include?(repo) }
    invalid_repos.blank? ? true : raise("Invalid repo: #{invalid_repos} was provided for deployment profile")
  end

  # we want to determine if all of the inputs provided in request are part of the given profile
  # @param [String] profile_id
  # @param [Hash] inputs
  def valid_inputs?(profile_id, inputs)
    allowed_profile_inputs = DeploymentProfile.find_by_profile_id(profile_id).inputs.pluck(:human_name)
    invalid_inputs = inputs.keys.select { |input| !allowed_profile_inputs.include?(input) }
    invalid_inputs.blank? ? true : raise("Invalid input #{invalid_inputs} was provided for deployment profile")
  end


end