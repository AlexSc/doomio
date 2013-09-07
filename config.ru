$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require 'newrelic_rpm'

require 'app'

run Doomio
