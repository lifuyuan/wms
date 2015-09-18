require_dependency "wms/application_controller"

module Wms
  class Android::WmsApiController < ApplicationController
  	skip_before_filter :verify_authenticity_token
  	before_filter :authenticate_user_from_android_token!,:except=>[:sign_in]

    
    # 登录
  	def sign_in
	    account = Wms::Account.where(name: params[:name]).first
	    if account && account.authenticate(params[:password])
	    	account.ensure_android_token
	    	render json: {token: account.android_token}
	    else
	    	render json: {info: "name or password not right"}, status: "404"
	    end
	  end

    # 获取商户
	  def obtain_merchant
	  	merchant = Merchant.all
	  	if merchant.count > 0
	  		render json: {merchant: merchant.map{|a| {a.name => a.id.to_s}}}
	  	else
	  		render json: {info: "There is no merchant"}, status: "404"
	  	end
	  end

	  # 获取预报批次号
	  def inquire_inbound_no
  		mic = Wms::MerInboundCommodity.where(inbound_depot: @account.depot.name, :status.in => ["accepted"], :inbound_status.in => ["partial-entered","non-enetered"])
  		render json: {inbound_no: mic.map{|m| m.inbound_no}}
	  end

	  # 入库
	  def inbound_commodity
	  	begin
				mdibc_params=params
		  	merchantId = mdibc_params[:merchantId].presence
	      merchant = merchantId && Merchant.where(id: merchantId.to_s).first
	      raise "Your request data is wrong" unless merchant
	      inboundNo = mdibc_params[:inboundNo].presence
	      mic = inboundNo && Wms::MerInboundCommodity.where(inbound_no: inboundNo.to_s).first
	    	mdibc = Wms::MerDeoptInboundBatchCommodity.new(new_mdibc_params(mic))
	    	mdibc.merchant = merchant
	    	raise "MerDeoptInboundBatchCommodity Failed" unless mdibc.save
	    	i = 0
	    	mis = []
	    	mdibss = []
	    	mbss = []
	    	inbound_params = JSON.parse mdibc_params[:inboundBarcode]
	    	inbound_params.each do |barcode_params|
	    		logger.info "params: #{barcode_params['commodityBarcode']} #{barcode_params['quantity']}"
	    		commodityBarcode = barcode_params['commodityBarcode'].presence
	    		quantity = (barcode_params['quantity'].presence || 1).to_i

	    		logger.info "params: #{commodityBarcode} #{quantity}"
	    		ms = commodityBarcode && Wms::MerSku.where(merchant: merchant, barcode: commodityBarcode).first
	    		mbs = commodityBarcode && Wms::MerBatchSku.where(mer_inbound_commodity: mic, commodity_no: commodityBarcode).first
	    		raise "Sku Info not exists" unless ms || mbs
	    		mdibs = Wms::MerDepotInboundBatchSku.new(new_mdibs_params(ms, mbs, quantity))
	    		mdibs.mer_depot_inbound_batch_commodity = mdibc
	    		raise "MerDepotInboundBatchSku Failed" unless mdibs.save
	    		mdibss[i] = mdibs
	    		mi = Wms::MerInventory.new(new_mi_params(mdibs))
	    		mi.merchant = merchant
	    		raise "MerInventory Failed" unless mi.save
	    		mis[i] = mi
	    		mbss[i] = mbs
					i+=1
	    	end

	    	# 更新mer_batch_sku
	    	update_mbss = {}
	    	i = 0
	    	mbss.each do |mbs|
	    		if mbs
		    		status = mbs.status
		    		mdibcs = Wms::MerDeoptInboundBatchCommodity.where(merchant: mbs.mer_inbound_commodity.merchant, inbound_no: mbs.mer_inbound_commodity.inbound_no)
		    		amount = 0
		    		mdibcs.each do |mdibc|
		    			amount += mdibc.mer_depot_inbound_batch_skus.sum{|m| m.quantity}
		    		end

		    		if amount >= mbs.quantity
		    			mbs.status = "entered"
		    		else
		    			mbs.status = "partial-entered"
		    		end

		    		raise "MerBatchSku Failed" unless mbs.save
		    		update_mbss[mbs] = status
		    	end
	    	end

	    	# 更新mer_inbound_commodity
	    	if mic 
	    		mic_status = mic.inbound_status

	    		if mic.mer_batch_skus.where(:status.in => ["partial-entered","non-entered"]).first
	    			mic.inbound_status = "partial-entered"
	    		else
	    			mic.inbound_status = "entered"
	    		end

	    		raise "MerInboundCommodity" unless mic.save
	    	end

	    	render json: {info: "successful"} 
	    rescue=>e
	    	info=e.message
	    	logger.info "ERROR: #{info}"
	    	mdibc.delete if mdibc
	    	mdibss.each {|mdibs| mdibs.delete} if mdibss
	    	mis.each {|mi| mi.delete} if mis
	    	if update_mbss
	    		update_mbss.each {|key, value| if key; key.update_attributes(status: value); end}
	    	end
	    	if mic_status
	    		mic.update_attributes(inbound_status: mic_status) 
	    	end
	    	render json: {info: info}, status: "400"
	    end
	  end

    # 上架
	  def mount_commodity
	  	
	  end








	  private
	  	def new_mdibc_params(mic)
				mdibc={}
				if mic
					mdibc['inbound_no'] = mic.inbound_no
					mdibc['inbound_type'] = "sc"
					mdibc['inbound_depot'] = @account.depot.name
					mdibc['mer_email'] = mic.mer_email
					mdibc['commodity_owner'] = mic.commodity_owner
					mdibc['return_carrier'] = mic.return_carrier
					mdibc['consignor'] = mic.consignor
					mdibc['memo'] = mic.memo
				else
					mdibc['inbound_type'] = "non-sc"
					mdibc['inbound_depot'] = @account.depot.name
				end

				mdibc
			end

			def new_mdibs_params(ms, mbs, quantity)
				mdibs={}
				if mbs 
					mdibs['sku_no']=mbs.sku_no
					mdibs['commodity_no']=mbs.commodity_no
					mdibs['dom']=mbs.dom
					mdibs['deadline_of_shelf_life']=mbs.deadline_of_shelf_life
				else
					mdibs['sku_no']=ms.sku_no
					mdibs['commodity_no']=ms.barcode
					mdibs['dom']= ""
					mdibs['deadline_of_shelf_life']= ""
				end
				mdibs['quantity']=quantity
				mdibs['mounted_quantity']=0
				mdibs['oper_type']="addition"
				mdibs['operator']=@account.name
				mdibs['operator_id']=@account.id.to_s
				mdibs['status']="non-mounted"
				mdibs['memo']=""
				mdibs
			end

			def new_mi_params(mdibs)
				mi={}
				mi['depot_batch_sku_sid']=mdibs.depot_batch_sku_sid
				mi['sku_no']=mdibs.sku_no
				mi['sku_extra_no']=mdibs.sku_extra_no
				mi['commodity_no']=mdibs.commodity_no
				mi['quantity']=mdibs.quantity
				mi['availiable_quantity']=mdibs.quantity
				mi['inbound_depot']=mdibs.mer_depot_inbound_batch_commodity.inbound_depot
				mi['mer_email']=mdibs.mer_depot_inbound_batch_commodity.mer_email
				mi['commodity_owner']=mdibs.mer_depot_inbound_batch_commodity.commodity_owner
				mi
			end
  end
end
