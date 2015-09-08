# encoding: utf-8
class Wms::Settings < Settingslogic
  source "#{Wms::Engine.root}/config/settings.yml"
  namespace Rails.env
end