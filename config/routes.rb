Wms::Engine.routes.draw do
  root to: "accounts#welcome"
	get "login" => "accounts#login", :as => "login"
  get "signup" => "accounts#signup", :as => "signup"
  post "create_login_session" => "accounts#create_login_session"
  delete "logout" => "accounts#logout", :as => "logout"

  namespace :android do
    post 'accounts/sign_in' => 'wms_api#sign_in'
    get 'merchants' => 'wms_api#obtain_merchant'
    get 'inbound_nos' => "wms_api#inquire_inbound_no"
    get 'inbound_batch_nos' => 'wms_api#inquire_inbound_batch_no'
    post 'inbound' => "wms_api#inbound_commodity"
    post 'mount' => "wms_api#mount_commodity"
    post 'sorting' => "wms_api#sorting_commodity"
    post 'unbound' => "wms_api#unbound_commodity"
  end
  resources :accounts, only: [:create]
  resources :depots, only: [:edit, :update]
  get "depots/show" => "depots#show_depot", :as => "show_depot"
  get "depots/shelf_barcode" => "depots#shelf_barcode", :as => "shelf_barcode"
  resources :mer_inbound_commodities, only: [:index, :show] do
    get 'status', on: :member
  end

  resources :mer_depot_inbound_batch_commodities, only: [:index, :show]

  resources :mer_inventories, only: [:index]

  resources :mer_outbound_orders, only: [:index, :show] do
    post 'choose', on: :collection
    get 'allocate', on: :collection
    post 'allocated', on: :collection
    get 'merge', on: :collection
    post 'merged', on: :collection
  end

  resources :mer_waves, only: [:index] do 
    post 'sorting_pdf', on: :collection
    get 'order_pdf', on: :member
  end
end
