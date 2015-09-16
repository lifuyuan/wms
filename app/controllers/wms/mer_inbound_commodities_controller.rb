require_dependency "wms/application_controller"

module Wms
  class MerInboundCommoditiesController < ApplicationController
  	before_filter :check_login
  	
  	layout 'wms/inbound_layout'

    def index
    	@mer_inbound_commodities = Wms::MerInboundCommodity.all
    end

    def show
    end
  end
end
