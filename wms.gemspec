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
  s.add_dependency "mongoid", "~> 4.0.2"
  s.add_dependency "bcrypt", "~> 3.1.7"
  s.add_dependency "sass-rails", "~> 5.0"
  s.add_dependency 'coffee-rails', '~> 4.1.0'
  s.add_dependency 'uglifier', '>= 1.3.0'
  s.add_dependency "jquery-rails"
  s.add_dependency "turbolinks"
  s.add_dependency "settingslogic", "~> 2.0.9"
  s.add_dependency "cancan", "~> 1.6.10"
  s.add_dependency 'prawn', '~> 1.2.1'
  s.add_dependency 'prawn-table', '~> 0.1.1'
  s.add_dependency 'barby', '~> 0.5.1'
  s.add_dependency 'rqrcode', '~> 0.4.2'
  s.add_dependency 'rmagick', '~> 2.15.4'
  s.add_dependency 'chunky_png', '~> 1.3.0'

  s.add_development_dependency "sqlite3"
end
