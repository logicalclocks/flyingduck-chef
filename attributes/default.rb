include_attribute "conda"
include_attribute "hops"
include_attribute "hadoop_spark"

default['flyingduck']['version']                = "3.4.0" 
default['flyingduck']['download_url']           = "#{node['install']['enterprise']['download_url']}/flyingduck/#{node['flyingduck']['version']}/flyingduck.tgz"
default['flyingduck']['port']                   = 5005
default['flyingduck']['monitoring']             = 12810

default['flyingduck']['user']                   = "flyingduck"
default['flyingduck']['user_id']                = '1525'
default['flyingduck']['group']                  = "flyingduck"
default['flyingduck']['group_id']               = '1520'

default['flyingduck']['home']                   = "#{node['install']['dir']}/flyingduck"
default['flyingduck']['logs']                   = "#{node['flyingduck']['home']}/logs"
default['flyingduck']['etc']                    = "#{node['flyingduck']['home']}/etc"

# Max amount of memory to use in DuckDB. Reduce for a test VM.
default['flyingduck']['memory_gbs']             = "16"
default['flyingduck']['cpus']                   = "4"

# Configuration parameters 
default['flyingduck']['request_timeout_sec']    = "600"
default['flyingduck']['batch_size']             = "65536"

# Data volume directories
default['flyingduck']['data_volume']['root_dir']  = "#{node['data']['dir']}/flyingduck"
default['flyingduck']['data_volume']['logs_dir']  = "#{node['flyingduck']['data_volume']['root_dir']}/logs"
default['flyingduck']['data_volume']['etc_dir']  = "#{node['flyingduck']['data_volume']['root_dir']}/etc"
