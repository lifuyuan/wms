require_dependency "wms/application_controller"

module Wms
  class Android::WmsApiController < ApplicationController
  	skip_before_filter :verify_authenticity_token

  	def sign_in
  		logger.info params[:name]
  		logger.info params[:password]
	    account = Wms::Account.where(name: params[:name]).first
	    if account && account.authenticate(params[:password])
	    	account.ensure_android_token
	    	render json: {token: account.android_token}
	    else
	    	render json: {info: "name or password not right"}, status: "404"
	    end
	  end
  end
end
