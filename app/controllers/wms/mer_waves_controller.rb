require_dependency "wms/application_controller"

module Wms
  class MerWavesController < ApplicationController
  	before_filter :check_login
  	
  	layout 'wms/outbound_layout'

    def index
    	@mer_waves = Wms::MerWave.where(assigned_id: current_account.id).desc(:status)
    end

    def seeding_tasks
      @mer_waves = Wms::MerWave.where(assigned_id: current_account.id, flag: "seeding").desc(:status)
    end

    def picking_tasks
      @mer_waves = Wms::MerWave.where(assigned_id: current_account.id, flag: "picking").desc(:status)
    end

    def sorting_pdf
      mer_waves = Wms::MerWave.find(params[:mw_id])
      output = MerWavePrint.new.batch_mer_wave(mer_waves)
      send_data output, :type => "application/pdf", :filename => "Sorting.pdf", :disposition => "attachment", :encoding => 'gb2312'
    end

    def order_pdf
      mer_wave = Wms::MerWave.find(params[:id])
      order_ids = []
      mer_wave.mer_wave_skus.each {|mws| order_ids = order_ids + mws.refered_orders}
      orders = Wms::MerOutboundOrder.find(order_ids)
      output = MerOrderPrint.new.batch_order(orders)
      send_data output, :type => "application/pdf", :filename => "Order.pdf", :disposition => "attachment", :encoding => 'gb2312'
    end
  end
end
