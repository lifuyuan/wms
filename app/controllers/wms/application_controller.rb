module Wms
  class ApplicationController < ActionController::Base
  	protect_from_forgery with: :exception

  	def current_account
    	@current_account ||= Wms::Account.where(token: cookies[:token]).first if cookies[:token]
  	end

  	def check_admin
	    unless current_account && current_account.has_role?(:admin)
	      redirect_to :root, :notice => "Only admin can do this."
	    end
	  end

	  def check_login
      session[:return_to] = request.original_url
    	redirect_to :login, :notice => "Must Sign in" if current_account.blank?
  	end

    def authenticate_user_from_android_token!
      token = params[:token].presence
      @account = token && Wms::Account.where(android_token: token.to_s).first
      render json: {info: "Your token has expired, please log in again"}, status: "404" and return unless @account
    end

  	helper_method :current_account
  end
end
