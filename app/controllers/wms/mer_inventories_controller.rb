require_dependency "wms/application_controller"

module Wms
  class MerInventoriesController < ApplicationController
  	before_filter :check_login
  	
  	layout 'wms/inbound_layout'

    def index
    	@mer_inventories = Wms::MerInventory.where(inbound_depot: current_account.depot.name, :quantity.gt => 0)
    end

  end
end
