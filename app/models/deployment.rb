class Deployment < ActiveRecord::Base
  belongs_to :DeploymentProfile
  attr_accessible :deployment_guid, :status
end
