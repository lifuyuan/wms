Wms::Engine.routes.draw do
  root to: "accounts#welcome"
	get "login" => "accounts#login", :as => "login"
  get "signup" => "accounts#signup", :as => "signup"
  post "create_login_session" => "accounts#create_login_session"
  delete "logout" => "accounts#logout", :as => "logout"
  resources :accounts, only: [:create]
end
