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
	    	render json: {token: account.android_token, role: account.role.name, depot: account.depot.name}
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
  		mics = Wms::MerInboundCommodity.where(inbound_depot: @account.depot.name, :status.in => ["accepted"], :inbound_status.in => ["partial-entered","non-entered"])
  		render json: {inbound_no: mics.map{|m| m.inbound_no}}
	  end

	  # 批量入库
	  def inbound_commodity_batch
	  	begin
				mdibc_params=params
		  	merchantId = mdibc_params[:merchantId].presence
	      merchant = merchantId && Merchant.where(id: merchantId.to_s).first
	      raise "400" unless merchant
	      inboundNo = mdibc_params[:inboundNo].presence
	      mic = inboundNo && Wms::MerInboundCommodity.where(inbound_no: inboundNo.to_s).first
	      if mic
	      	raise "401" unless ["partial-entered","non-entered"].include? mic.inbound_status
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
	    	info = "500" unless info.start_with?("4")
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
	    	render json: {info: info}, status: info
	    end
	  end

	  # 单个入库
	  def inbound_commodity
	  	begin
				mdibc_params=params
		  	merchantId = mdibc_params[:merchantId].presence
	      merchant = merchantId && Merchant.where(id: merchantId.to_s).first
	      raise "400" unless merchant
	      inboundNo = mdibc_params[:inboundNo].presence
	      mic = Wms::MerInboundCommodity.where(merchant: merchant, inbound_no: inboundNo.to_s).first
	      raise "408" unless mic
	      raise "401" unless ["partial-entered", "non-entered"].include? mic.inbound_status
	    	unless mdibc_e = Wms::MerDeoptInboundBatchCommodity.where(inbound_no: inboundNo).first
	    		mdibc = Wms::MerDeoptInboundBatchCommodity.new(new_mdibc_params(mic))
	    		mdibc.merchant = merchant
	    		raise "402" unless mdibc.save
	    		mdibc_e = mdibc
	    	end

    		commodityBarcode = mdibc_params[:commodityBarcode].presence
    		quantity = (mdibc_params[:quantity].presence || 1).to_i

    		logger.info "params: #{commodityBarcode} #{quantity}"
    		ms = commodityBarcode && Wms::MerSku.where(merchant: merchant, barcode: commodityBarcode).first
    		mbs = commodityBarcode && Wms::MerBatchSku.where(mer_inbound_commodity: mic, commodity_no: commodityBarcode).first
    		raise "403" unless ms || mbs
    		unless mdibs_e = Wms::MerDepotInboundBatchSku.where(mer_depot_inbound_batch_commodity: mdibc_e, commodity_no: commodityBarcode).first
	    		mdibs = Wms::MerDepotInboundBatchSku.new(new_mdibs_params(ms, mbs, quantity))
	    		mdibs.mer_depot_inbound_batch_commodity = mdibc_e
	    		raise "404" unless mdibs.save
	    		mdibs_e = mdibs
	    	else
	    		mdibs_e.quantity = mdibs_e.quantity + 1
	    		raise "409" unless mdibs_e.save
    		end
    		unless mi_e = Wms::MerInventory.where(depot_batch_sku_sid: mdibs_e.depot_batch_sku_sid, commodity_no: commodityBarcode).first
	    		mi = Wms::MerInventory.new(new_mi_params(mdibs_e))
	    		mi.merchant = merchant
	    		raise "405" unless mi.save
	    		mi_e = mi
	    	else
	    		mi_e.quantity = mi_e.quantity + 1
	    		mi_e.availiable_quantity = mi_e.availiable_quantity + 1
	    		raise "410" unless mi_e.save
	    	end
    		# 更新mer_batch_sku
    		update_mbss = {}
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

	    	# 更新mer_inbound_commodity
    		mic_status = mic.inbound_status

    		if mic.mer_batch_skus.where(:status.in => ["partial-entered","non-entered"]).first
    			mic.inbound_status = "partial-entered"
    		else
    			mic.inbound_status = "entered"
    		end

    		raise "407" unless mic.save

	    	render json: {info: "successful"} 
	    rescue=>e
	    	info=e.message
	    	info = "500" unless info.start_with?("4")
	    	logger.info "ERROR: #{info}"
	    	mdibc.delete if mdibc.presence
	    	if mdibs
	    		mdibs.delete
	    	else
	    		if mdibs_e
	    			mdibs_e.quantity = mdibs_e.quantity - 1
	    			mdibs_e.save
	    		end
	    	end
	    	if mi
	    		mi.delete
	    	else
	    		if mi_e
		    		mi_e.quantity = mi_e.quantity - 1
		    		mi_e.availiable_quantity = mi_e.availiable_quantity - 1
		    		mi_e.save
		    	end
	    	end
	    	if update_mbss.presence
	    		update_mbss.each {|key, value| if key; key.update_attributes(status: value); end}
	    	end
	    	if mic_status
	    		mic.update_attributes(inbound_status: mic_status) 
	    	end
	    	render json: {info: info}, status: info
	    end
	  end

	  # 获取预报批次号
	  def inquire_inbound_batch_no
  		mdibcs = Wms::MerDeoptInboundBatchCommodity.where(inbound_depot: @account.depot.name)
  		render json: {inbound_no: mdibcs.map{|m| m.inbound_batch_no}}
	  end

    # 批量上架
	  def mount_commodity_batch
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
	  		info = "500" unless info.start_with?("4")
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

    # 单个上架
	  def mount_commodity
	  	begin
	  		mdibc = Wms::MerDeoptInboundBatchCommodity.where(inbound_batch_no: params[:inboundBatchNo]).first
	  		raise "400" unless mdibc
	  		shelf_no = params[:shelfNum].presence
	  		raise "401" unless shelf_no
	  		update_mdibss = {}
  			commodityBarcode = params[:commodityBarcode].presence
    		quantity = (params[:quantity].presence || "1").to_i
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
  			unless mms_e = Wms::MerMountedSku.where(inbound_batch_no: mdibs.mer_depot_inbound_batch_commodity.inbound_batch_no, commodity_no: commodityBarcode).first
  				mms = Wms::MerMountedSku.new(new_mms_params(mdibs, shelf_no))
  				raise "405" unless mms.save
  			end
  			unless mmsl_e = Wms::MerMountedSkuLog.where(inbound_batch_no: mdibs.mer_depot_inbound_batch_commodity.inbound_batch_no, commodity_no: commodityBarcode).first
	  			mmsl = Wms::MerMountedSkuLog.new(new_mmsl_params(mdibs, shelf_no, "mount"))
	  			raise "406" unless mmsl.save
  			end
	  		render json: {info: "successful"} 
	  	rescue=>e
	  		info=e.message
	  		info = "500" unless info.start_with?("4")
	    	logger.info "ERROR: #{info}"
	  		if update_mdibss.presence
		  		update_mdibss.each do |key, value|
		  			key.update_attributes(mounted_quantity: value[0], status: value[1])
		  		end
	  	  end

	  	  mms.delete if mms.presence

	  	  mmsl.delete if mmsl.presence

	  	  render json: {info: info}, status: info
	  	end
	  end

	  # 批量分拣
	  def sorting_commodity_batch
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
				info = "500" unless info.start_with?("4")
				if mwss.presence
					mwss.each {|key,value| key.update_attributes(allocated_quantity: value)}
				end
				if mw_status
					mw.update_attributes(status: mw_status)
				end
				render json: {info: info}, status: info
	  	end
	  end

	  # 单个分拣
	  def sorting_commodity
	  	begin
	  		mw = Wms::MerWave.where(wave_no: params[:waveNo]).first
	  		raise "400" unless mw
	  		mw_status = mw.status

  			commodityBarcode = params[:commodityBarcode].presence
    		quantity = (params[:quantity].presence || "1").to_i
    		mws = mw.mer_wave_skus.where(commodity_no: commodityBarcode).first
    		raise "402" unless mws
    		raise "403" if mws.allocated_quantity + quantity > mws.quantity
    		mws.allocated_quantity = mws.allocated_quantity + quantity
    		raise "404" unless mws.save

	  		isFinish = true
	  		mw.mer_wave_skus.each {|mws| isFinish = false if mws.allocated_quantity < mws.quantity }
	  		if isFinish
	  			mw.status = "finished"
	  			raise "405" unless mw.save
	  		end
	  		render json: {info: "successful"} 
	  	rescue=>e
				info=e.message
				info = "500" unless info.start_with?("4")
				if mws
					mws.allocated_quantity = mws.allocated_quantity - quantity
					mws.save
				end
				if mw_status
					mw.update_attributes(status: mw_status)
				end
				render json: {info: info}, status: info
	  	end
	  end


	  def unbound_commodity
	  	begin
	  		moo = Wms::MerOutboundOrder.where(tp_order_no: params[:orderNo]).first
	  		raise "400" unless moo
	  		moo_status = moo.status
	  		raise "401" unless moo.update_attributes(status: "gathered")
	  		mdoo = Wms::MerDepotOutboundOrder.new(new_mdoo_params(moo))
	  		mdoo.sender = moo.sender
	  		mdoo.recipient = moo.recipient
	  		raise "402" unless mdoo.save
	  		outbound_params = JSON.parse params[:outboundBarcode]
	  		raise "403" if outbound_params.size == 0
	  		mis = {}
	  		mdobss = []
	  		i = 0
	  		outbound_params.each do |outbound_barcode|
	  			commodityBarcode = outbound_barcode['commodityBarcode'].presence
	    		quantity = outbound_barcode['quantity'].presence.to_i
	    		mbs = moo.mer_batch_skus.where(commodity_no: commodityBarcode).first
	    		raise "404" unless mbs
	    		mdobs = Wms::MerDepotOutboundBatchSku.new(new_mdobs_params(mbs, quantity))
	    		mdobs.mer_depot_outbound_order = mdoo
	    		raise "405" unless mdobs.save
	    		mdobss[i] = mdobs
	    		i += 1
	    		Wms::MerInventory.where(merchant: moo.mer_outbound_commodity.merchant, commodity_no: commodityBarcode).asc(:created_at).each do |mi|
	    			mis[mi] = mi.quantity
	    			quantity = mi.quantity - quantity
	    			mi.quantity = quantity >= 0 ? quantity : mi.quantity
	    			raise "406" unless mi.save
	    			break if quantity >= 0
	    		end
	    		raise "407" if quantity < 0
	    	end
	    	render json: {info: "successful"} 
	  	rescue=>e
	  		info = e.message
	  		info = "500" unless info.start_with?("4")
	  		moo.update_attributes(status: moo_status) if moo_status.presence
	  		mdoo.delete if mdoo.presence
	  		if mis.presence
	  			mis.each {|key, value| key.update_attributes(quantity: value)}
	  		end

	  		if mdobss.presence
	  			mdobss.each {|m| m.delete}
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

			def new_mdoo_params(moo)
				mdoo = {}
				mdoo['order_no'] = moo.order_no
				mdoo['outbound_no'] = moo.mer_outbound_commodity.outbound_no
				mdoo['tp_order_no'] = moo.tp_order_no
				mdoo['tp_order_datetime'] = moo.tp_order_datetime
				mdoo['customer_id'] = moo.customer_id
				mdoo['total_price'] = moo.total_price
				mdoo['cp_price'] = moo.cp_price
				mdoo['currency'] = moo.currency
				mdoo['payor'] = moo.payor
				mdoo['payment_method'] = moo.payment_method
				mdoo['payment_datetime'] = moo.payment_datetime
				mdoo['payment_price'] = moo.payment_price
				mdoo['payment_currency'] = moo.payment_currency
				mdoo['main_carrier'] = moo.main_carrier
				mdoo['status'] = "gathered"
				mdoo['outbound_method'] = moo.outbound_method
				mdoo['wave_no'] = moo.wave_no
				mdoo
			end

			def new_mdobs_params(mbs, gathered_quantity)
				mdobs = {}
				mdobs['depot_batch_sku_sid'] = mbs.batch_sku_sid
				mdobs['sku_no'] = mbs.sku_no
				mdobs['sku_extra_no'] = ''
				mdobs['commodity_no'] = mbs.commodity_no
				mdobs['quantity'] = mbs.quantity
				mdobs['gathered_quantity'] = gathered_quantity
				mdobs['oper_type'] = "addition"
				mdobs['status'] = "gathered"
				mdobs['operator'] = @account.name
				mdobs['operator_id'] = @account.id.to_s
				mdobs
			end
  end
end
