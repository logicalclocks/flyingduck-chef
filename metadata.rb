name              "flyingduck"
maintainer        "Logical Clocks"
maintainer_email  'info@logicalclocks.com'
license           'GPLv3'
description       'Installs/Configures the Hopsworks online feature store service'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "2.6.0"

recipe "flyingduck::default", "Configures the Hopsworks online feature store service"

depends 'ndb'
depends 'hops'
depends 'kagent'
depends 'consul'

attribute "flyingduck/user",
          :description => "User to run the online feature store service",
          :type => "string"

attribute "flyingduck/user_id",
          :description => "flyingduck user id. Default: 1521",
          :type => "string"

attribute "flyingduck/group",
          :description => "Group of the user running the online feature store service",
          :type => "string"

attribute "flyingduck/group_id",
          :description => "flyingduck group id. Default: 1516",
          :type => "string"

attribute "flyingduck/monitoring",
          :description => "Port on which the monitoring page is available",
          :type => "string"

attribute "flyingduck/download_url",
          :description => "Download url for the flyingduck.tgz binaries",
          :type => "string"
