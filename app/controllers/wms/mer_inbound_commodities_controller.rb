require_dependency "wms/application_controller"

module Wms
  class MerInboundCommoditiesController < ApplicationController
  	before_filter :check_login
  	
  	layout 'wms/inbound_layout'

    def index
    	@mer_inbound_commodities = Wms::MerInboundCommodity.where(inbound_depot: current_account.depot.name)
    end

    def show
      @mer_inbound_commodity = Wms::MerInboundCommodity.find(params[:id])
    end

    def status
      @mer_inbound_commodity = Wms::MerInboundCommodity.find(params[:id])
      @mer_inbound_commodity.update_attributes(status: params[:status])
      redirect_to mer_inbound_commodities_path
    end
  end
end
