class Input < ActiveRecord::Base
  attr_accessible :human_name, :rs_name
  belongs_to :deployment_profile

end
