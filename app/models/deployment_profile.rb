class DeploymentProfile < ActiveRecord::Base
  attr_accessible :profile_id, :rs_account, :rs_array, :rs_deployment, :rs_array_name
  has_many :deployments
  has_many :inputs, :dependent => :destroy
  has_many :repos, :through => :deployment_profile_repos
  has_many :deployment_profile_repos
  after_create :add_default_inputs
  include DnsmadeeasyHelper

  DEFAULT_INPUTS = {:DEPLOYMENT_ID => :DEPLOY_ID, :APPLICATION_TAG => :APP_TAG}

  def self.create_from_array(array,inputs,repos,domain)
    new_profile = DeploymentProfile.new
    new_profile.profile_id = SecureRandom.hex.to_s
    new_profile.rs_account = array.href.split('/')[5]
    new_profile.rs_array = array.href.split('/').last
    new_profile.rs_deployment = array.deployment_href.split('/').last
    new_profile.rs_array_name = array.nickname
    new_profile.domain = domain
    inputs.each do |input|
      new_profile.inputs.build(:human_name => input, :rs_name => "server_array[parameters][#{input}]")
    end
    repos.each do |repo_id|
      new_profile.deployment_profile_repos.build(:repo_id => repo_id)
    end
    new_profile.save!
    new_profile
  end

  def self.available_domains
    dns_client = Dns.new
    dns_client.list_domains
  end

  def add_default_inputs
    DEFAULT_INPUTS.each do |input_name,type|
      self.inputs.build(:human_name => input_name.to_s, :rs_name => "server_array[parameters][#{input_name.to_s}]", :input_type => type )
    end
    self.save!
  end

end
