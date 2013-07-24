class DeploymentProfileRepo < ActiveRecord::Base
  attr_accessible :deployment_profile_id, :repo_id
  belongs_to :deployment_profile
  belongs_to :repo
end
