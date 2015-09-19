require_dependency "wms/application_controller"

module Wms
  class DepotsController < ApplicationController
  	before_filter :check_login
  	layout 'wms/inbound_layout'
  	def show_depot
  		@depot = current_account.depot
  	end

  	def edit
  		@depot = current_account.depot
  	end

  	def update
  		@depot = current_account.depot
  		@depot.update_attributes(depot_params)
  		redirect_to show_depot_path, notice: "Edit Successful"
  	end


  	private
	  	def depot_params
	      params.require(:depot).permit(:shelf_num)
	    end
  end
end
