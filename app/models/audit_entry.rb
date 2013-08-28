class AuditEntry < ActiveRecord::Base
  belongs_to :deployment
  attr_accessible :audit_type, :details
end
