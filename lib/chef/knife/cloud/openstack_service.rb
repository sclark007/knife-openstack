# frozen_string_literal: true
#
# Author:: Siddheshwar More (<siddheshwar.more@clogeny.com>)
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2013 Chef Software, Inc.
#

require "chef/knife/cloud/fog/service"

class Chef
  class Knife
    class Cloud
      class OpenstackService < FogService
        def initialize(options = {})
          Chef::Log.debug("openstack_username #{Chef::Config[:knife][:openstack_username]}")
          Chef::Log.debug("openstack_auth_url #{Chef::Config[:knife][:openstack_auth_url]}")
          Chef::Log.debug("openstack_tenant #{Chef::Config[:knife][:openstack_tenant]}")
          Chef::Log.debug("openstack_endpoint_type #{Chef::Config[:knife][:openstack_endpoint_type] || 'publicURL'}")
          Chef::Log.debug("openstack_insecure #{Chef::Config[:knife][:openstack_insecure]}")
          Chef::Log.debug("openstack_region #{Chef::Config[:knife][:openstack_region]}")

          super(options.merge(auth_params: get_auth_params))
        end

        # add alternate user defined api_endpoint value.
        def add_api_endpoint
          @auth_params.merge!(openstack_auth_url: Chef::Config[:knife][:api_endpoint]) unless Chef::Config[:knife][:api_endpoint].nil?
        end

        def get_server(search_term)
          if server = connection.servers.get(search_term)
            return server
          end

          if servers = connection.servers.all(name: search_term)
            if servers.length > 1
              error_message = "Multiple server matches found for '#{search_term}', use an instance_id to be more specific."
              ui.fatal(error_message)
              raise CloudExceptions::ValidationError, error_message
            else
              servers.first
            end
          end
        rescue Excon::Errors::BadRequest => e
          handle_excon_exception(CloudExceptions::KnifeCloudError, e)
        end

        def get_auth_params
          load_fog_gem
          params = {
            provider: "OpenStack",
            connection_options: {
              ssl_verify_peer: !Chef::Config[:knife][:openstack_insecure],
            },
          }

          (
            Fog::Compute::OpenStack.requirements +
            Fog::Compute::OpenStack.recognized -
            [:openstack_api_key]
          ).each do |k|
            next unless k.to_s.start_with?("openstack")
            params[k] = Chef::Config[:knife][k]
          end
          params[:openstack_api_key] = Chef::Config[:knife][:openstack_password] || Chef::Config[:knife][:openstack_api_key]

          params
        end
      end
    end
  end
end
