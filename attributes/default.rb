#include_attribute "kkafka"
#include_attribute "ndb"
include_attribute "hops"

default['flyingduck']['version']                = "1.3.1"
default['flyingduck']['download_url']           = "#{node['download_url']}/flyingduck/#{node['flyingduck']['version']}/flyingduck.tgz"

default['flyingduck']['user']                   = "flyingduck"
default['flyingduck']['user_id']                = '1744'
default['flyingduck']['group']                  = "flyingduck"
default['flyingduck']['group_id']               = '1744'

default['flyingduck']['home']                   = "#{node['install']['dir']}/flyingduck"
default['flyingduck']['etc']                    = "#{node['flyingduck']['home']}/etc"
default['flyingduck']['logs']                   = "#{node['flyingduck']['home']}/logs"
default['flyingduck']['token']                  = "#{node['flyingduck']['etc']}/token"

# Data volume directories
default['flyingduck']['data_volume']['root_dir']  = "#{node['data']['dir']}/flyingduck"
default['flyingduck']['data_volume']['etc_dir']   = "#{node['flyingduck']['data_volume']['root_dir']}/etc"
default['flyingduck']['data_volume']['logs_dir']  = "#{node['flyingduck']['data_volume']['root_dir']}/logs"

default['flyingduck']['monitoring']             = 13900

default['flyingduck']['hopsworks']['email']     = "flyingduck@hopsworks.ai"
default['flyingduck']['hopsworks']['password']  = "flyingduckpw"
