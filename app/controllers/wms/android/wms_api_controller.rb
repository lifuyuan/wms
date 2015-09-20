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
  		mics = Wms::MerInboundCommodity.where(inbound_depot: @account.depot.name, :status.in => ["accepted"], :inbound_status.in => ["partial-entered","non-enetered"])
  		render json: {inbound_no: mics.map{|m| m.inbound_no}}
	  end

	  # 入库
	  def inbound_commodity
	  	begin
				mdibc_params=params
		  	merchantId = mdibc_params[:merchantId].presence
	      merchant = merchantId && Merchant.where(id: merchantId.to_s).first
	      raise "400" unless merchant
	      inboundNo = mdibc_params[:inboundNo].presence
	      mic = inboundNo && Wms::MerInboundCommodity.where(inbound_no: inboundNo.to_s).first
	      if mic
	      	raise "401" unless ["partial-entered","non-enetered"].include? mic.inbound_status
	    	end
	    	mdibc = Wms::MerDeoptInboundBatchCommodity.new(new_mdibc_params(mic))
	    	mdibc.merchant = merchant
	    	raise "402" unless mdibc.save
	    	i = 0
	    	mis = []
	    	mdibss = []
	    	update_mbss = {}
	    	inbound_params = JSON.parse mdibc_params[:inboundBarcode]
	    	inbound_params.each do |barcode_params|
	    		logger.info "params: #{barcode_params['commodityBarcode']} #{barcode_params['quantity']}"
	    		commodityBarcode = barcode_params['commodityBarcode'].presence
	    		quantity = (barcode_params['quantity'].presence || 1).to_i

	    		logger.info "params: #{commodityBarcode} #{quantity}"
	    		ms = commodityBarcode && Wms::MerSku.where(merchant: merchant, barcode: commodityBarcode).first
	    		mbs = commodityBarcode && Wms::MerBatchSku.where(mer_inbound_commodity: mic, commodity_no: commodityBarcode).first
	    		raise "403" unless ms || mbs
	    		mdibs = Wms::MerDepotInboundBatchSku.new(new_mdibs_params(ms, mbs, quantity))
	    		mdibs.mer_depot_inbound_batch_commodity = mdibc
	    		raise "404" unless mdibs.save
	    		mdibss[i] = mdibs
	    		mi = Wms::MerInventory.new(new_mi_params(mdibs))
	    		mi.merchant = merchant
	    		raise "405" unless mi.save
	    		mis[i] = mi
	    		# 更新mer_batch_sku
	    		if mbs
		    		update_mbss[mbs] = mbs.status
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
		    		raise "406" unless mbs.save
		    	end
					i+=1
	    	end

	    	# 更新mer_inbound_commodity
	    	if mic 
	    		mic_status = mic.inbound_status

	    		if mic.mer_batch_skus.where(:status.in => ["partial-entered","non-entered"]).first
	    			mic.inbound_status = "partial-entered"
	    		else
	    			mic.inbound_status = "entered"
	    		end

	    		raise "407" unless mic.save
	    	end

	    	render json: {info: "successful"} 
	    rescue=>e
	    	info=e.message
	    	logger.info "ERROR: #{info}"
	    	mdibc.delete if mdibc.presence
	    	mdibss.each {|mdibs| mdibs.delete} if mdibss.presence
	    	mis.each {|mi| mi.delete} if mis.presence
	    	if update_mbss.presence
	    		update_mbss.each {|key, value| if key; key.update_attributes(status: value); end}
	    	end
	    	if mic_status
	    		mic.update_attributes(inbound_status: mic_status) 
	    	end
	    	render json: {info: info}, status: "400"
	    end
	  end

	  # 获取预报批次号
	  def inquire_inbound_batch_no
  		mdibcs = Wms::MerDeoptInboundBatchCommodity.where(inbound_depot: @account.depot.name)
  		render json: {inbound_no: mdibcs.map{|m| m.inbound_batch_no}}
	  end

    # 上架
	  def mount_commodity
	  	begin
	  		mdibc = Wms::MerDeoptInboundBatchCommodity.where(inbound_batch_no: params[:inboundBatchNo]).first
	  		raise "400" unless mdibc
	  		shelf_no = params[:shelfNum].presence
	  		raise "401" unless shelf_no
	  		logger.info params[:mountedBarcode]
	  		mount_params = JSON.parse params[:mountedBarcode]
	  		logger.info mount_params
	  		raise "402" if mount_params.size == 0
	  		i = 0
	  		update_mdibss = {}
	  		mmss = []
	  		mmsls = []
	  		mount_params.each do |mount_barcode|
	  			commodityBarcode = mount_barcode['commodityBarcode'].presence
	    		quantity = mount_barcode['quantity'].presence.to_i
	    		logger.info commodityBarcode
	  			mdibs = mdibc.mer_depot_inbound_batch_skus.where(commodity_no: commodityBarcode).first
	  			raise "403" unless mdibs
	  			update_mdibss[mdibs] = [mdibs.mounted_quantity, mdibs.status]
	  			mdibs.mounted_quantity = mdibs.mounted_quantity + quantity
	  			if mdibs.quantity <= mdibs.mounted_quantity
	  				mdibs.status = "mounted"
	  			else
	  				mdibs.status = "partially-mounted"
	  			end
	  			raise "404" unless mdibs.save

	  			mms = Wms::MerMountedSku.new(new_mms_params(mdibs, shelf_no))
	  			raise "405" unless mms.save
	  			mmss[i] = mms
	  			mmsl = Wms::MerMountedSkuLog.new(new_mmsl_params(mdibs, shelf_no, "mount"))
	  			raise "406" unless mmsl.save
	  			mmsls[i] = mmsl
	  			i += 1
	  		end

	  		render json: {info: "successful"} 
	  	rescue=>e
	  		info=e.message
	    	logger.info "ERROR: #{info}"
	  		if update_mdibss.presence
		  		update_mdibss.each do |key, value|
		  			key.update_attributes(mounted_quantity: value[0], status: value[1])
		  		end
	  	  end

	  	  if mmss.presence
	  	  	mmss.each {|m| m.delete}
	  	  end

	  	  if mmsls.presence
	  	  	mmsls.each {|m| m.delete}
	  	  end

	  	  render json: {info: info}, status: info
	  	end
	  end

	  # 分拣
	  def sorting_commodity
	  	begin
	  		mw = Wms::MerWave.where(wave_no: params[:waveNo]).first
	  		raise "400" unless mw
	  		mw_status = mw.status
	  		sorting_params = JSON.parse params[:sortingBarcode]
	  		raise "401" if sorting_params.size == 0
	  		mwss = {}
	  		sorting_params.each do |sorting_barcode|
	  			commodityBarcode = sorting_barcode['commodityBarcode'].presence
	    		quantity = sorting_barcode['quantity'].presence.to_i
	    		mws = mw.mer_wave_skus.where(commodity_no: commodityBarcode).first
	    		raise "402" unless mws
	    		raise "403" if mws.allocated_quantity + quantity > mws.quantity
	    		mwss[mws] = mws.allocated_quantity
	    		mws.allocated_quantity = mws.allocated_quantity + quantity
	    		raise "404" unless mws.save
	  		end
	  		isFinish = true
	  		mw.mer_wave_skus.each {|mws| isFinish = false if mws.allocated_quantity < mws.quantity }
	  		if isFinish
	  			mw.status = "finished"
	  			raise "405" unless mw.save
	  		end
	  		render json: {info: "successful"} 
	  	rescue=>e
				info=e.message
				if mwss.presence
					mwss.each {|key,value| key.update_attributes(allocated_quantity: value)}
				end
				if mw_status
					mw.update_attributes(status: mw_status)
				end
				render json: {info: info}, status: info
	  	end
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

			def new_mms_params(mdibs, shelf_no)
				mms = {}
				mms['sku_no'] = mdibs.sku_no
				mms['sku_extra_no'] = mdibs.sku_extra_no
				mms['commodity_no'] = mdibs.commodity_no
				mms['inbound_batch_no'] = mdibs.mer_depot_inbound_batch_commodity.inbound_batch_no
				mms['dom'] = mdibs.dom
				mms['deadline_of_shelf_life'] = mdibs.deadline_of_shelf_life
				mms['shelf_no'] = shelf_no
				mms['operator'] = @account.name
				mms['operator_id'] = @account.id.to_s
				mms
			end

			def new_mmsl_params(mdibs, shelf_no, oper_type)
				mmsl = {}
				mmsl['sku_no'] = mdibs.sku_no
				mmsl['sku_extra_no'] = mdibs.sku_extra_no
				mmsl['commodity_no'] = mdibs.commodity_no
				mmsl['inbound_batch_no'] = mdibs.mer_depot_inbound_batch_commodity.inbound_batch_no
				mmsl['shelf_no'] = shelf_no
				mmsl['operator'] = @account.name
				mmsl['operator_id'] = @account.id.to_s
				mmsl['oper_type'] = oper_type
				mmsl
			end
  end
end
