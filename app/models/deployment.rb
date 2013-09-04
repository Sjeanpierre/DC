class Deployment < ActiveRecord::Base
  belongs_to :deployment_profile
  has_many :deployment_details, :dependent => :destroy
  has_many :audit_entries, :dependent => :destroy
  attr_accessible :deployment_guid, :status
  before_create :generate_deployment_guid, :set_initial_status
  after_update :create_audit_entry, :if => :status_changed?
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

  def create_audit_entry
    self.audit_entries.build(:audit_type => :update, :details => "status updated from #{self.status_change[0]} to #{self.status_change[1]}")
  end

  def retrieve_audit_entries
    audit_entries = self.audit_entries
    #need to verify that the map returns items in the correct order
    audit_entries.map {|ae| {:time => ae.created_at.to_formatted_s(:db), :event => ae.audit_type, :details => ae.details}}
  end

  def handle_deployment_failure(error)
    self.audit_entries.build(:audit_type => :failure, :details => "deployment failed with the following error #{error.message}")
  end

  def process_deployment(request) #rescue errors in this method and send it to a notifier method to add failure to audit trail as well as send a notification
    self.update_attributes(:status => 'processing')
    begin
      deployment_details = perform_deployment(request)
      populate_deployment_details(deployment_details)
    rescue => error
      handle_deployment_failure(error)
    end
  end

  def populate_deployment_details(details_hash)
    self.update_attributes(:status => 'booting')
    github_info = details_hash[:tag_info]
    dns_info = details_hash[:dns_info]
    rightscale_info = details_hash[:rs_info]
    github_info.each do |info|
      self.deployment_details.build(:resource => 'git_info', :type => 'sha', :value => info.sha)
      self.deployment_details.build(:resource => 'git_info', :type => 'tag', :value => info.tag)
    end
    self.deployment_details.build(:resource => 'rs_info', :type => 'instance_href', :value => rightscale_info.instance_href)
    self.deployment_details.build(:resource => 'dns_info', :type => 'sub_domain', :value => dns_info.subdomain_name)
    self.deployment_details.build(:resource => 'dns_info', :type => 'dns_id', :value => dns_info.dns_id)
    self.save!
  end
end
