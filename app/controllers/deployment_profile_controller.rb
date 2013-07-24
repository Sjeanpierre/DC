class DeploymentProfileController < ApplicationController
  include RightscaleHelper
  include GithubHelper
  include DnsmadeeasyHelper

  def index
    @deployment_profiles = DeploymentProfile.all
  end

  def new
    rs_client = Rightscale.new(params[:rsaccount])
    @grouped_arrays = rs_client.get_grouped_arrays
  end

  def destroy

  end

  def show
    @deployment_profile = DeploymentProfile.find(params[:id])
  end

  def select_inputs
    array_id = params[:deployment_profile][:rs_array]
    rs_client = Rightscale.new(params[:rsaccount])
    @inputs = rs_client.get_array_inputs(array_id)
    @array = rs_client.find(:resource => 'array', :field => 'id', :value => array_id)
  end


  def save
    rs_client = Rightscale.new(params[:rsaccount])
    array_id = params[:deployment_profile][:array_id]
    selected_inputs = params[:deployment_profile][:inputs].reject {|element| element.blank? or !element.is_a?(String)}
    selected_repos = params[:deployment_profile][:repos].reject {|element| element.blank?}
    selected_domain = params[:deployment_profile][:domain]
    array = rs_client.find(:resource => 'array', :field => 'id', :value => array_id)
    DeploymentProfile.create_from_array(array,selected_inputs,selected_repos,selected_domain)
    redirect_to :action => 'index'
  end
end
