require_dependency "wms/application_controller"

module Wms
  class AccountsController < ApplicationController
    def welcome
    end

    def signup
    	@account = Wms::Account.new
    end

    def login
    end

    def logout
    	cookies.delete(:token)
    	redirect_to root_url
  	end

  	def create_login_session
	    account = Wms::Account.where(name: params[:name]).first
	    if account && account.authenticate(params[:password])
	      cookies.permanent[:token] = account.token
	      redirect_to root_url
	    else
	      redirect_to "/wms/login"
	    end
  	end

  	def create
	    @account = Wms::Account.new(account_params)
	    if @account.save
	      cookies.permanent[:token] = @account.token
	      redirect_to "/wms"
	    else
	      render :signup
	    end
	  end

	  private
	   def account_params
	     params.require(:account).permit!
	   end
  end
end
