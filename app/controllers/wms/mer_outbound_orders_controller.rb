require_dependency "wms/application_controller"

module Wms
  class MerOutboundOrdersController < ApplicationController
  	before_filter :check_login
    before_filter :check_admin, except: [:index, :show]
  	
  	layout 'wms/outbound_layout'

    def index
    	@mer_outbound_commodities = Wms::MerOutboundCommodity.where(outbound_depot: current_account.depot.name)
    end

    def show
    end

    def choose
      redirect_to mer_outbound_orders_path, notice: "You must select at least one orders" and return unless params[:moo_id].presence
      redirect_to mer_outbound_orders_path, notice: "You must select operation type" and return unless params[:choose].presence
      session[:moo_id] = params[:moo_id]
      if params[:choose][:way] == "allocate"
        render action: "allocate"
      elsif params[:choose][:way] == "merge"
        if params[:moo_id].size <= 1
          session[:moo_id] = nil
          redirect_to mer_outbound_orders_path, notice: "You must select at least two orders" and return
        end
        render action: "merge"
      end
    end

    def allocate
    end

    def allocated
      begin
        account = Wms::Account.find(params[:staff_id])
        moos = {}
        j = 0
        mvs = []
        i = 0
        wmss = []
        session[:moo_id].each do |moo_id|
          @mer_outbound_order = Wms::MerOutboundOrder.find(moo_id)
          moos[@mer_outbound_order] = @mer_outbound_order.status
          raise "MerOutboundOrder update failed!" unless @mer_outbound_order.update_attributes(status: "allocated", outbound_method: "picking")
          mv = Wms::MerWave.new(wave_no: @mer_outbound_order.tp_order_no, 
            refered_amount: 1,
            allocator: current_account.name,
            allocator_id: current_account.id,
            assigned_name: account.name,
            assigned_id: account.id,
            status: "in-process")
          raise "MerWave save failed!" unless mv.save
          mvs[j] = mv
          j += 1
          @mer_outbound_order.mer_batch_skus.each do |mbs|
            mooa = [@mer_outbound_order.id]
            wms = Wms::MerWaveSku.new(sku_no: mbs.sku_no,
              commodity_no: mbs.commodity_no,
              quantity: mbs.quantity,
              allocated_quantity: 0)
            wms.refered_orders = mooa
            wms.allocated_orders = mooa
            wms.mer_wave = mv
            raise "MerWaveSku save failed!" unless wms.save
            wmss[i] = wms
            i += 1
          end
        end
        session[:moo_id] = nil
        redirect_to mer_outbound_orders_path, notice: "allocate successful!"
      rescue=>e
        if moos.presence
          moos.each {|key, value| key.update_attributes(status: value, outbound_method: nil)}
        end
        if mvs.presence
          mvs.each {|mv| mv.delete}
        end
        if wmss.presence
          wmss.each {|wms| wms.delete}
        end
        session[:moo_id] = nil
        redirect_to mer_outbound_orders_path, notice: e.message
      end

    end

    def merge
    end

    def merged
      begin
        account = Wms::Account.find(params[:staff_id])
        mv = Wms::MerWave.new( 
          refered_amount: session[:moo_id].size,
          allocator: current_account.name,
          allocator_id: current_account.id,
          assigned_name: account.name,
          assigned_id: account.id,
          status: "in-process")
        raise "MerWave save failed!" unless mv.save
        moos = {}
        wmss = []
        i = 0
        session[:moo_id].each do |moo_id|
          @mer_outbound_order = Wms::MerOutboundOrder.find(moo_id)
          moos[@mer_outbound_order] = @mer_outbound_order.status
          raise "MerOutboundOrder update failed!" unless @mer_outbound_order.update_attributes(status: "allocated", outbound_method: "seeding", wave_no: mv.wave_no)
          @mer_outbound_order.mer_batch_skus.each do |mbs|
            if mws = mv.mer_wave_skus.where(sku_no: mbs.sku_no).first
              mws.quantity = mws.quantity + mbs.quantity
              mws.allocated_orders << @mer_outbound_order.id
              mws.refered_orders << @mer_outbound_order.id
              raise "MerWaveSku update failed!" unless mws.save
            else
              mooa = [@mer_outbound_order.id]
              mws = Wms::MerWaveSku.new(sku_no: mbs.sku_no,
                commodity_no: mbs.commodity_no,
                quantity: mbs.quantity,
                allocated_quantity: 0)
              mws.refered_orders = mooa
              mws.allocated_orders = mooa
              mws.mer_wave = mv
              raise "MerWaveSku save failed!" unless mws.save
              wmss[i] = mws
              i += 1
            end
          end
        end
        session[:moo_id] = nil
        redirect_to mer_outbound_orders_path, notice: "Seeding To a Wave successful!"
      rescue=>e
        mv.delete if mv.presence
        if moos.presence
          moos.each {|key,value| key.update_attributes(status: "value", outbound_method: nil, wave_no: nil)}
        end

        if wmss.presence
          wmss.each {|w| w.delete}
        end
        redirect_to mer_outbound_orders_path, notice: e.message
      end
    end
  end
end
