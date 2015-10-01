require_dependency "wms/application_controller"

module Wms
  class MerInventoriesController < ApplicationController
  	before_filter :check_login
  	
  	layout 'wms/inbound_layout'

    def index
    	@mer_inventories = Wms::MerInventory.where(inbound_depot: current_account.depot.name, :quantity.gt => 0)
    end

    def commodity_search
    	@mer_inventories = Wms::MerInventory.where(inbound_depot: current_account.depot.name, :quantity.gt => 0)
    	@mer_inventories = @mer_inventories.where(merchant_id: params[:merchant]) if params[:merchant].presence
    	@mer_inventories = @mer_inventories.where(commodity_no: params[:commodity]) if params[:commodity].presence
    	@mer_inventories = @mer_inventories.where(sku_no: params[:sku]) if params[:sku].presence
    end

  end
end
