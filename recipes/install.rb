### Nothing to do 


# Download and load the Docker image
image_url = node['flyingduck']['download_url']
base_filename = File.basename(image_url)
remote_file "#{Chef::Config['file_cache_path']}/#{base_filename}" do
  source image_url
  action :create
end
