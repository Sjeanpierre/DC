class DeploymentProfileController < ApplicationController
  include RightscaleHelper

  def index

  end

  def new
    rs_client = Rightscale.new(params[:rsaccount])
    @grouped_arrays = rs_client.get_grouped_arrays
  end

  def destroy

  end

  def show

  end

  def create
    array_id = params[:deployment_profile][:rs_array]
    rs_client = Rightscale.new(params[:rsaccount])
    @inputs = rs_client.get_array_inputs(array_id, Time.now.to_i)
    @array = rs_client.find(:resource => 'array', :field => 'id', :value => array_id)
  end

  def save
    rs_client = Rightscale.new(params[:rsaccount])
    array_id = params[:deployment_profile][:array_id]
    selected_inputs = params[:deployment_profile][:inputs].reject {|element| element.blank?}
    array = rs_client.find(:resource => 'array', :field => 'id', :value => array_id)
    DeploymentProfile.create_from_array(array,selected_inputs)
  end
end
