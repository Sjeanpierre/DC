class Array
  def to_hashie
    map {|array| Hashie::Mash.new(array)}
  end
end
module RightscaleHelper

  RESOURCES = %w{deployment array}
  ARRAY_PARAMS = %w{nickname href deployment id}
  DEPLOYMENT_PARAMS = %w{ tags nickname href}
  GOOD_RESPONSE_CODES = %w{204 201 200}
  RESOURCE_TYPES = %w{ec2_instance}

  require 'hashie'
  class Rightscale

    def self.new(account_id)
      @rs_client = RightScaleAPIHelper::Helper.new(account_id, Base64.decode64(RS_CONFIG['username']), Base64.decode64(RS_CONFIG['password']), format="js", version="1.0")
      self
    end

    def self.array(array_id)
      handle_rightscale_response(@rs_client.get("/server_arrays/#{array_id}"))
    end

    def self.arrays
      resp = @rs_client.get('/server_arrays')
      JSON.parse(resp.body).to_hashie
    end

    def self.array_instances(array)
      array_id = array.href.split('/').last.to_i
      handle_rightscale_response(@rs_client.get("/server_arrays/#{array_id}/instances"))
    end

    def self.deployments
      resp = @rs_client.get('/deployments')
      JSON.parse(resp.body).to_hashie
    end

    #find(:resource => 'array', :field => 'href', :value => 783)
    def self.find(options = {})
      if RESOURCES.include?(options[:resource])
        method = "find_#{options[:resource]}"
        send(method.to_sym,options)
      else
        handle_error("resource type #{options[:resource] || 'UNDEFINED'} is unknown")
      end
    end

    def self.find_array(options)
      if ARRAY_PARAMS.include?(options[:field])
        return self.array(options[:value]) if options[:field] == 'id'
        arrays = self.arrays
        arrays.select! {|array| array.send(options[:field]) == options[:value]}
      else
        handle_error("field name #{options[:field] || 'UNDEFINED'} is unknown")
      end
    end

    #if the user attempts to lookup a deployment or an array by ID we should not retrieve the full set but instead just use a method to get it directly
    def self.find_deployment(options)
      if DEPLOYMENT_PARAMS.include?(options[:field])
        deployments = self.deployments
        deployments.select! {|deployment| deployment.send(options[:field] == options[:value])}
      else
        handle_error("field name #{options[:field] || 'UNDEFINED'} is unknown")
      end
    end

    def self.get_array_inputs(array_id,profile_id)
      array = self.find(:resource => 'array', :field => 'id', :value => array_id)
      inputs = self.tag_array_instances(array, profile_id)
      inputs.first.parameters
    end

    def self.tag_array_instances(array, tag)
      instance_hrefs = self.array_instances(array)
      handle_error("No running instances in array #{array.nickname}") if instance_hrefs.blank?
      tags = {
          :resource_href => instance_hrefs.last.href,
          'tags[]' => tag
      }
      self.handle_rightscale_response(@rs_client.put('/tags/set', tags))
      resource = self.retrieve_resource_with_tag('ec2_instance', tag)
      self.handle_rightscale_response(@rs_client.put('/tags/unset', tags))
      return resource
    end

    def self.retrieve_resource_with_tag(resource, tag)
      if RESOURCE_TYPES.include?(resource)
        tags = { :resource_type => resource,
                 :tags => [*tag]
        }
        self.handle_rightscale_response(@rs_client.get("/tags/search", tags))
      end
    end

    #noinspection RubyDeadCode,RubyScope
    def self.get_grouped_arrays
      deployments = self.deployments
      arrays = self.arrays
      grouped_arrays = {}
      arrays.each do |array|
        array_info = [array.nickname, array.href.split('/').last.to_i]
        deployment_name = (deployments.detect {|deployment| deployment.href == array.deployment_href} || next ).nickname
        if grouped_arrays.has_key?(deployment_name)
          grouped_arrays[deployment_name].push(array_info)
        else
          grouped_arrays[deployment_name] = []
          grouped_arrays[deployment_name].push(array_info)
        end
      end
      grouped_arrays
    end

    def self.handle_rightscale_response(response)
      if GOOD_RESPONSE_CODES.include?(response.code)
        return unless response.body.present?
        body = JSON.parse(response.body)
        if body.is_a?(Array)
          body.to_hashie
        elsif body.is_a?(Hash)
          Hashie::Mash.new(body)
        end
      else
        self.handle_error("Rightscale returned error code #{response.code}")
      end
    end

    def self.handle_error(error)
      raise(error)
    end


  end
end