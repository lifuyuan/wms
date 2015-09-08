module Wms
  class ApplicationController < ActionController::Base
  	protect_from_forgery with: :exception

  	def current_account
    	@current_account ||= Wms::Account.where(token: cookies[:token]).first if cookies[:token]
  	end

  	def check_admin
	    unless current_account && current_account.admin?
	      redirect_to :root, :notice => "Only admin can do this."
	    end
	  end

	  def check_login
    	redirect_to :login, :notice => "Must Sign in" if current_account.blank?
  	end

  	helper_method :current_account
  end
end
