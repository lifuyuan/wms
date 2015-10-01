require_dependency "wms/application_controller"

module Wms
  class MerDepotInboundBatchCommoditiesController < ApplicationController
  	before_filter :check_login
  	
  	layout 'wms/inbound_layout'

    def index
    	@mer_depot_inbound_batch_commodities = Wms::MerDeoptInboundBatchCommodity.where(inbound_depot: current_account.depot.name)
    end

    def show
      @mer_depot_inbound_batch_commodity = Wms::MerDeoptInboundBatchCommodity.find(params[:id])
    end

  end
end
