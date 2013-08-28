class Input < ActiveRecord::Base
  attr_accessible :human_name, :rs_name, :input_type
  belongs_to :deployment_profile

  def self.defaults
    where('input_type is not null').all
  end

end
