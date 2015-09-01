module Wms
  class ApplicationController < ActionController::Base
  	protect_from_forgery with: :exception

  	def current_account
    	@current_account ||= Wms::Account.where(token: cookies[:token]).first if cookies[:token]
  	end

  	helper_method :current_account
  end
end
