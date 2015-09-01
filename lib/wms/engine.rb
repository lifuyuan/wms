require "mongoid"

module Wms
  class Engine < ::Rails::Engine
    isolate_namespace Wms

    config.generators do |g|
		  g.assets false
		  g.helper false
		  g.test_framework false
		end
  end
end
