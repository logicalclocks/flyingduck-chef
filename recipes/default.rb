group node['flyingduck']['group'] do
  gid node['flyingduck']['group_id']
  action :create
  not_if "getent group #{node['flyingduck']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['flyingduck']['user'] do
  home node['flyingduck']['user-home']
  uid node['flyingduck']['user_id']
  gid node['flyingduck']['group']
  action :create
  shell "/bin/nologin"
  manage_home true
  system true
  not_if "getent passwd #{node['flyingduck']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end


## Start - in case flying duck is not on the same server as the NameNode, create HDFS user + crypto
## This host must also install at least hops::client

include_recipe "hops::hdfs_user"

## End - in case flying duck is not on the same server as the NameNode, create HDFS user + crypto

group node['logger']['group'] do
  gid node['logger']['group_id']
  action :create
  not_if "getent group #{node['logger']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['logger']['user'] do
  uid node['logger']['user_id']
  gid node['logger']['group_id']
  shell "/bin/nologin"
  action :create
  system true
  not_if "getent passwd #{node['logger']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['flyingduck']['group'] do
  append true
  members [node['logger']['user']]
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['hops']['secure_group'] do
  action :modify
  members node['flyingduck']['user']
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

directory node['flyingduck']['data_volume']['root_dir'] do
  owner node['flyingduck']['user']
  group node['flyingduck']['group']
  mode "0750"
  action :create
end

directory node['flyingduck']['data_volume']['etc_dir'] do
  owner node['flyingduck']['user']
  group node['flyingduck']['group']
  mode "0750"
  action :create
end

directory node['flyingduck']['data_volume']['logs_dir'] do
  owner node['flyingduck']['user']
  group node['flyingduck']['group']
  mode "0750"
  action :create
end

['etc_dir', 'logs_dir'].each {|dir|
  directory node['flyingduck']['data_volume'][dir] do
    owner node['flyingduck']['user']
    group node['flyingduck']['group']
    mode "0750"
    action :create
  end
}

directory node['flyingduck']['home'] do
  owner node['flyingduck']['user']
  group node['flyingduck']['group']
  mode "0750"
  action :create
end

['etc', 'logs'].each {|dir|
  bash "Move flyingduck #{dir} to data volume" do
    user 'root'
    code <<-EOH
      set -e
      mv -f #{node['flyingduck'][dir]}/* #{node['flyingduck']['data_volume']["#{dir}_dir"]}
      rm -rf #{node['flyingduck'][dir]}
    EOH
    only_if { conda_helpers.is_upgrade }
    only_if { File.directory?(node['flyingduck'][dir])}
    not_if { File.symlink?(node['flyingduck'][dir])}
  end

  link node['flyingduck'][dir] do
    owner node['flyingduck']['user']
    group node['flyingduck']['group']
    mode "0750"
    to node['flyingduck']['data_volume']["#{dir}_dir"]
  end
}

# Generate a certificate
#service_fqdn = node['fqdn']
service_fqdn = consul_helper.get_service_fqdn("namenode")

crypto_dir = x509_helper.get_crypto_dir(node['hops']['hdfs']['user'])

# Generate an API key
api_key = nil
ruby_block 'generate-api-key' do
  block do
    require 'net/https'
    require 'http-cookie'
    require 'json'
    require 'securerandom'

    hopsworks_fqdn = consul_helper.get_service_fqdn("hopsworks.glassfish")
    _, hopsworks_port = consul_helper.get_service("glassfish", ["http", "hopsworks"])
    if hopsworks_port.nil? || hopsworks_fqdn.nil?
      raise "Could not get Hopsworks fqdn/port from local Consul agent. Verify Hopsworks is running with service name: glassfish and tags: [http, hopsworks]"
    end

    hopsworks_endpoint = "https://#{hopsworks_fqdn}:#{hopsworks_port}"
    url = URI.parse("#{hopsworks_endpoint}/hopsworks-api/api/auth/service")
    api_key_url = URI.parse("#{hopsworks_endpoint}/hopsworks-api/api/users/apiKey")

    params =  {
      :email => node['flyingduck']['hopsworks']['email'],
      :password => node['flyingduck']['hopsworks']["password"]
    }

    api_key_params = {
      :name => "flyingduck_" + SecureRandom.hex(12),
      :scope => "FEATURESTORE"
    }

    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 120
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    jar = ::HTTP::CookieJar.new

    http.start do |connection|

      request = Net::HTTP::Post.new(url)
      request.set_form_data(params, '&')
      response = connection.request(request)

      if( response.is_a?( Net::HTTPSuccess ) )
          # your request was successful
          puts "Flyingduck login successful: -> #{response.body}"

          response.get_fields('Set-Cookie').each do |value|
            jar.parse(value, url)
          end

          api_key_url.query = URI.encode_www_form(api_key_params)
          request = Net::HTTP::Post.new(api_key_url)
          request['Content-Type'] = "application/json"
          request['Cookie'] = ::HTTP::Cookie.cookie_value(jar.cookies(api_key_url))
          request['Authorization'] = response['Authorization']
          response = connection.request(request)

          if ( response.is_a? (Net::HTTPSuccess))
            json_response = ::JSON.parse(response.body)
            api_key = json_response['key']
          else
            puts response.body
            raise "Error creating flyingduck api-key: #{response.uri}"
          end
      else
          puts response.body
          raise "Error flyingduck login"
      end
    end
  end
end

# write api-key to token file
file node['flyingduck']['token'] do
  content lazy {api_key}
  mode 0750
  owner node['flyingduck']['user']
  group node['flyingduck']['group']
end

# Template the configuration file
nn_fqdn = consul_helper.get_service_fqdn("namenode")

template "#{node['flyingduck']['etc']}/flyingduck-site.xml" do
  source "flyingduck-site.xml.erb"
  owner node['flyingduck']['user']
  group node['flyingduck']['group']
  mode 0750
  variables(
    {
      :nn_fqdn => nn_fqdn,
      :nn_port => node['hops']['nn']['port']
    }
  )
end

template "#{node['flyingduck']['etc']}/log4j.properties" do
  source "log4j.properties.erb"
  owner node['flyingduck']['user']
  group node['flyingduck']['group']
  mode 0750
end

# Docker image already downloaded in install.rb
image_url = node['flyingduck']['download_url']
base_filename = File.basename(image_url)

# Load the Docker image
#registry_image = "#{consul_helper.get_service_fqdn("registry")}:#{node['hops']['docker']['registry']['port']}/flyingduck:#{node['flyingduck']['version']}"
registry_image = "#{consul_helper.get_service_fqdn("registry")}:#{node['hops']['docker']['registry']['port']}/flyingduck"
#image_name = "docker.hops.works:4443/flyingduck:#{node['flyingduck']['version']}"
image_name = "flyingduck:#{node['flyingduck']['version']}"
bash "import_image" do
  user "root"
  code <<-EOF
    set -e
    docker load -i #{Chef::Config['file_cache_path']}/#{base_filename}
    docker tag #{image_name} #{registry_image}
    docker push #{registry_image}
  EOF
  not_if "docker image inspect #{registry_image}"
end

# Add Systemd unit file
service_name="flyingduck"
case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/#{service_name}.service"
else
  systemd_script = "/lib/systemd/system/#{service_name}.service"
end

service service_name do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

local_systemd_dependencies = ""
if service_discovery_enabled()
  local_systemd_dependencies += "consul.service"
end
if exists_local("hops", "nn")
  local_systemd_dependencies += " namenode.service"
end

hops_dir = node['hops']['base_dir']
spark_dir = node['hadoop_spark']['base_dir']
anaconda_dir = node['conda']['base_dir']

template systemd_script do
  source "#{service_name}.service.erb"
  owner "root"
  group "root"
  mode 0664
  action :create
  if node['services']['enabled'] == "true"
    notifies :enable, "service[#{service_name}]"
  end
  variables({
    :crypto_dir => crypto_dir,
    :nn_fqdn => nn_fqdn,
    :nn_port => node['hops']['nn']['port'],
    :spark_dir => spark_dir,
    :hops_dir => hops_dir,
    :anaconda_dir => anaconda_dir,
    :flyingduck_fqdn => service_fqdn,    
    :local_dependencies => local_systemd_dependencies,
    :registry_image => registry_image
  })
end

kagent_config "#{service_name}" do
  action :systemd_reload
end

# Register with kagent
if node['kagent']['enabled'] == "true"
  kagent_config service_name do
    service "flyingduck"
  end
end

# Register with consul
if service_discovery_enabled()
  # Register flyingduck with Consul
  #consul_service "Registering Flyingduck with Consul" do
  #  service_definition "flyingduck.hcl.erb"
  #  action :register
  #end
end
