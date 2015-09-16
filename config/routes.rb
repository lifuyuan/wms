Wms::Engine.routes.draw do
  root to: "accounts#welcome"
	get "login" => "accounts#login", :as => "login"
  get "signup" => "accounts#signup", :as => "signup"
  post "create_login_session" => "accounts#create_login_session"
  delete "logout" => "accounts#logout", :as => "logout"

  namespace :android do
    post 'accounts/sign_in' => 'wms_api#sign_in'
  end
  resources :accounts, only: [:create]
  resources :mer_inbound_commodities
end
