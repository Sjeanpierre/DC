class DeploymentDetail < ActiveRecord::Base
  belongs_to :deployment
  attr_accessible :type, :value, :resource
end
