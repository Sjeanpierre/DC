class DeploymentProfile < ActiveRecord::Base
  attr_accessible :profile_id, :rs_account, :rs_array, :rs_deployment, :rs_array_name
  has_many :deployments

  def self.create_from_array(array,inputs)
    newprofile = DeploymentProfile.new
    newprofile.profile_id = SecureRandom.hex
    newprofile.rs_account = array.href.split('/')[5]
    newprofile.rs_array = array.href.split('/').last
    newprofile.rs_deployment = array.deployment_href.split('/').last
    newprofile.rs_array_name = array.nickname
    #newprofile.save!
  end
end
