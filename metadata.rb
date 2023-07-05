name              "flyingduck"
maintainer        "Logical Clocks"
maintainer_email  'info@logicalclocks.com'
license           'GPLv3'
description       'Installs/Configures the Hopsworks online feature store service'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "3.4.0"

recipe "flyingduck::default", "Configures the Hopsworks online feature store service"

depends 'ndb'
depends 'hops'
depends 'hadoop_spark'
depends 'kagent'
depends 'consul'

attribute "flyingduck/user",
          :description => "Unix user to store flyingduck data",
          :type => "string"

attribute "flyingduck/user_id",
          :description => "flyingduck user id",
          :type => "string"

attribute "flyingduck/group",
          :description => "Group of the user running the online feature store service",
          :type => "string"

attribute "flyingduck/group_id",
          :description => "flyingduck group id",
          :type => "string"

attribute "flyingduck/monitoring",
          :description => "Port on which the monitoring page is available",
          :type => "string"

attribute "flyingduck/port",
          :description => "Port on which AFS listens. Default: 5005",
          :type => "string"

attribute "flyingduck/download_url",
          :description => "Download url for the flyingduck.tgz binaries",
          :type => "string"


attribute "flyingduck/memory_gbs",
          :description => "Upper Memory limit for FlyingDuck service.",
          :type => "string"

attribute "flyingduck/cpus",
          :description => "Number of CPUs the FlyingDuck service can use.",
          :type => "string"

attribute "flyingduck/request_timeout_sec",
          :description => "Client will wait for this timeout in seconds for requests, after which an exception is thrown if no response.",
          :type => "string"

attribute "flyingduck/batch_size",
          :description => "Size of batches retrieved from Parquet files. Higher is higher throughput, but also higher latency",
          :type => "string"

attribute "flyingduck/data_volume/root_dir",
          :description => "Path to store data. Defaults to /srv/hops/hopsworks-data/flyingduck",
          :type => "string"

attribute "flyingduck/data_volume/etc_dir",
          :description => "Path to store config files. Defaults to flyingduck/etc",
          :type => "string"

attribute "flyingduck/data_volume/logs_dir",
          :description => "Path to store config files. Defaults to flyingduck/logs",
          :type => "string"

attribute "flyingduck/hopsworks/email",
          :description => "Email address",
          :type => "string"

attribute "flyingduck/hopsworks/password",
          :description => "Password for email address",
          :type => "string"


