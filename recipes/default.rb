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

[
  node['flyingduck']['home'],
  node['flyingduck']['data_volume']['root_dir']
].each {|dir|
  directory dir do
    owner node['flyingduck']['user']
    group node['flyingduck']['group']
    mode "0750"
    action :create
  end
}

directory node['flyingduck']['data_volume']['logs_dir'] do
  owner node['flyingduck']['user']
  group node['flyingduck']['group']
  mode "0750"
  action :create
end

link node['flyingduck']['logs'] do
  owner node['flyingduck']['user']
  group node['flyingduck']['group']
  mode "0750"
  to node['flyingduck']['data_volume']["logs_dir"]
end

# Generate a certificate
flyingduck_fqdn = consul_helper.get_service_fqdn("flyingduck")

crypto_dir = x509_helper.get_crypto_dir(node['flyingduck']['user'])
kagent_hopsify "Generate x.509" do
  user node['flyingduck']['user']
  crypto_directory crypto_dir
  common_name flyingduck_fqdn 
  action :generate_x509
  not_if { node["kagent"]["enabled"] == "false" }
end

# Docker image already downloaded in install.rb
image_url = node['flyingduck']['download_url']
base_filename = File.basename(image_url)
remote_file "#{Chef::Config['file_cache_path']}/#{base_filename}" do
  source image_url
  headers get_ee_basic_auth_header()
  sensitive true
  action :create
end

# Load the Docker image
registry_image = "#{consul_helper.get_service_fqdn("registry")}:#{node['hops']['docker']['registry']['port']}/flyingduck:#{node['flyingduck']['version']}"
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
    :flyingduck_fqdn => flyingduck_fqdn,
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
  consul_service "Registering Flyingduck with Consul" do
    service_definition "flyingduck.hcl.erb"
    action :register
  end
end
