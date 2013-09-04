class DeploymentController < ApplicationController
  include DeploymentHelper
  protect_from_forgery :except => :request_deployment

  def request_deployment
    request = validate_request(params[:request])
    deployment = Deployment.create_from_profile(request.profile_id)
    deployment.process_deployment(request) #delay(:queue => 'process_deployment').process_deployment(request)
    render :text => {:guid => deployment.deployment_guid}.to_json, :status => 201
  end

  def history
    deployment = Deployment.find_by_deployment_guid(params[:deployment_guid])
    audit_entries = deployment.retrieve_audit_entries
    render :text => audit_entries.to_json
  end
end
