# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

GW_CONFIG = YAML::load_file( File.join( Rails.root, 'config', 'gateway.yml' ) )
