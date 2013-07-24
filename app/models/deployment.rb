class Deployment < ActiveRecord::Base
  belongs_to :deployment_profile
  has_many :deployment_details
  attr_accessible :deployment_guid, :status
  before_create :generate_deployment_guid, :set_initial_status
  include DeploymentHelper

  def self.create_from_profile(profile_id)
    profile = DeploymentProfile.find_by_profile_id(profile_id)
    deployment = profile.deployments.new
    deployment.save
    deployment
  end

  def generate_deployment_guid
    self.deployment_guid = SecureRandom.hex.to_s
  end

  def set_initial_status
    self.status = 'queued'
  end

  def process_deployment(request) #rescue errors in this method and send it to a notifier method to add failure to audit trail as well as send a notification
    self.update_attributes(:status => 'processing')
    deployment_details = perform_deployment(request)
    populate_deployment_details(deployment_details)
    #tag associated github repositories
      #save tag and branch info in deployment details
    #create subdomain in dns made easy
      #save subdomain/dnsid info in deployment details
    #update rightscale inputs
    #launch machine
  end

  def populate_deployment_details(details_hash)
    self.update_attributes(:status => 'booting')
    github_info = details_hash[:tag_info]
    dns_info = details_hash[:dns_info]
    rightscale_info = details_hash[:rs_info]
    github_info.map! { |repo| repo[repo.keys[0]] }
    github_info.each do |details|
      details.each do |key,value|
        self.deployment_details.build(:resource => 'git_info', :type => key.to_s, :value => value)
      end
    end
    self.deployment_details.build(:resource => 'rs_info', :type => 'instance_href', :value => rightscale_info[:instance_href])
    self.deployment_details.build(:resource => 'dns_info', :type => 'sub_domain', :value => dns_info[:name] )
    self.deployment_details.build(:resource => 'dns_info', :type => 'dns_id', :value => dns_info[:id] )
    self.save!
  end
end
