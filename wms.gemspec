$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "wms/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "wms"
  s.version     = Wms::VERSION
  s.authors     = ["lifuyuan"]
  s.email       = ["lifuyuan33@gmail.com"]
  s.homepage    = "http://www.mypost4u.com/wms"
  s.summary     = "Wms function"
  s.description = "Wms function"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.3"

  s.add_development_dependency "sqlite3"
end
