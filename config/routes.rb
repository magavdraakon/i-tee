Rails.application.routes.draw do
  
  match 'storages/:id/edit', :to => 'storages#index', via: [:get, :post]
  resources :storages
  resources :lab_vmt_storages
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :assistants
  match 'ping', :to=>'home#ping', via:[:get, :post]

  get 'check_resources', :to=>'home#check_resources'

  match 'backup', :to=> 'home#backup', via: [ :get]
  match 'import/:name', :to=> 'home#import', via: [ :get]
  match 'export/:id', :to=> 'home#export', via: [ :get]
  match 'download_export/:name', :to=> 'home#download_export', via: [:get]
  match 'labinfo', :to=>'lab_users#labinfo', via: [:get, :post]

  match 'rdp_password', :to=>'virtualbox#rdp_password', via: [:get]
  match 'rdp_password', :to=>'virtualbox#update_password', via: [:post]
  match 'rdp_password', :to=>'virtualbox#remove_password', via: [:delete]

  match 'virtualization', :to =>'virtualbox#index', via: [:get, :post]
  match 'templates', :to =>'virtualbox#templates', via: [:get, :post]
  match 'manage_vm/:do/:name', :to=>'virtualbox#manage_vm', via:[:get]
  match 'manage_vm', :to=>'virtualbox#manage_vm', via:[:post]
  match 'vm_details/:name', :to=>'virtualbox#vm_details', via: [:get, :post]
  match 'virtualbox_guacamole/:name', :to=>'virtualbox#open_guacamole', via:[:get]

  match 'virtualbox_rdp/:name', :to=>'virtualbox#rdp_connection', via:[:get]  
  match 'virtualbox_readonly/:name', :to=>'virtualbox#readonly_connection', via:[:get]
  match 'rdp_admin', :to=>'virtualbox#rdp_admin', via:[:post]


  match 'jobs',:to=> 'home#jobs', via: [:get, :post]
  match 'jobs/:id', :to=>'home#delete_job', via: [:delete]
  match 'jobs/:id', :to=>'home#run_job', via: [:put]

  match 'networks/:id/edit', :to => 'networks#index', via: [:get, :post]
  resources :lab_vmt_networks

  resources :networks

  resources :user_badges

  resources :lab_badges

  resources :badges

  match 'users/sign_up', :to=>'home#catcher', via: [:get, :post]
  
  resources :lab_users
  match 'lab_users', :to=>'lab_users#destroy', via: [:delete]
  match 'lab_users', :to=>'lab_users#update', via: [:put]

  match 'set_vta_info', :to=>'lab_users#set_vta', via: [:post]

  resources :lab_vmts

  resources :vmts

  #devise_for :users,  :controllers => {:registrations => 'users/registrations', :passwords=> 'users/passwords'}

  devise_for :users, skip: [:sessions],  :controllers => {:registrations => 'users/registrations', :passwords=> 'users/passwords'}
  as :user do
    get 'sign_in', to: 'devise/sessions#new', as: :new_user_session
    post 'sign_in', to: 'devise/sessions#create', as: :user_session
    get 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  #match 'users/edit', :to=>'devise/registrations#edit'

  resources :users
  match 'users/:id', :to=>'users#destroy', via: [:delete]
  match 'users', :to=>'users#destroy', via: [:delete]
  match 'users', :to=>'users#update', via: [:put]

  resources :vms
  match 'vm_network', :to=>"vms#network", via: [:get, :post, :delete]  
  match 'vm_storage', :to=>"vms#storage", via: [:get, :post, :delete]
  match 'guestcontrol', :to=>"vms#guestcontrol", via: [:post]

  resources :materials
  
  resources :labs
  match 'labs', :to=>'labs#destroy', via: [:delete]
  match 'labs', :to=>'labs#update', via: [:put]

  resources :token_authentications, :only => [:update, :destroy]

  # route, :to => 'controller#action'
  
  match 'search', :to=> 'lab_users#search', via: [:get, :post]


  match 'lab_users/import', :to=>'lab_users#import', via: [:get, :post]
  match 'manage_tokens', :to=>'lab_users#user_token', via: [:get, :post]
  match 'edit_token', :to=>'token_authentications#edit', via: [:get, :post]
  match 'edit_token/:id', :to=>'token_authentications#edit', via: [:get, :post]
  
  match 'users/edit', :to=>'users#edit', via: [:get, :post]
  match 'users/edit/:id', :to=>'users#edit', via: [:get, :post]

  get 'error_401', :to => 'home#error_401'
  match 'template', :to => 'home#template', via: [:get, :post]
  match 'system', :to => 'home#system_info', via: [:get, :post]
  get 'about', :to=> 'home#about'
  #with user
  match 'start_all/:id/:username', :to=> 'vms#start_all', via: [:get, :post]
  match 'stop_all/:id/:username', :to=> 'vms#stop_all', via: [:get, :post]
  #with id
  match 'start_all/:id', :to=> 'vms#start_all', via: [:get, :post]
  match 'stop_all/:id', :to=> 'vms#stop_all', via: [:get, :post]

  match 'start_vm/:id', :to=> 'vms#start_vm', via: [:get, :post]
  match 'init_vm/:id', :to=> 'vms#init_vm', via: [:get, :post]
  match 'pause_vm/:id', :to=> 'vms#pause_vm', via: [:get, :post]
  match 'resume_vm/:id', :to=> 'vms#resume_vm', via: [:get, :post]
  match 'stop_vm/:id', :to=> 'vms#stop_vm', via: [:get, :post]
  match 'rdp_reset/:id', :to=> 'vms#rdp_reset', via: [:get, :post]

  match 'state_of', :to=> 'vms#get_state', via: [:get, :post]
  match 'rdp_of', :to=> 'vms#get_rdp', via: [:get, :post]
  match 'rdp_reset', :to=> 'vms#rdp_reset', via: [:get, :post]
  
  # guacamole
  match 'vm/:id/rdp', :to=>'vms#guacamole_view', via: [:get]
  match 'vm/:id/readonly', :to=>'vms#readonly_view', via: [:get]

    #no id
  match 'start_all', :to=> 'vms#start_all', via: [:get, :post]
  match 'stop_all', :to=> 'vms#stop_all', via: [:get, :post]
  match 'start_all_by_id', :to=> 'vms#start_all_by_id', via: [:get, :post]
  match 'stop_all_by_id', :to=> 'vms#stop_all_by_id', via: [:get, :post]
  match 'labuser_vms', :to=> 'vms#labuser_vms', via: [:get, :post]

  match 'start_vm', :to=> 'vms#start_vm', via: [:get, :post]
  match 'init_vm', :to=> 'vms#init_vm', via: [:get, :post]
  match 'pause_vm', :to=> 'vms#pause_vm', via: [:get, :post]
  match 'resume_vm', :to=> 'vms#resume_vm', via: [:get, :post]
  match 'stop_vm', :to=> 'vms#stop_vm', via: [:get, :post]
  
  match 'end_lab/:id', :to=>'labs#end_lab', via: [:get, :post]
  match 'end_lab', :to=>'labs#end_lab', via: [:get, :post]

  match 'start_lab/:id/:username', :to=>'labs#start_lab', via: [:get, :post]
  match 'start_lab/:id', :to=>'labs#start_lab', via: [:get, :post]
  match 'start_lab', :to=>'labs#start_lab', via: [:get, :post]

  match 'start_lab_by_id', :to=> 'labs#start_lab_by_id', via: [:post]
  match 'end_lab_by_id', :to=> 'labs#end_lab_by_id', via: [:post]
  match 'restart_lab_by_id', :to=> 'labs#restart_lab_by_id', via: [:post]

  match 'end_lab_by_values', :to=> 'labs#end_lab_by_values', via: [:post]

  match 'restart_lab/:id/:username', :to=> 'labs#restart_lab', via: [:get, :post]
  match 'restart_lab/:id', :to=> 'labs#restart_lab', via: [:get, :post]
  match 'restart_lab', :to=> 'labs#restart_lab', via: [:get, :post]

  match 'add_users/:id', :to=> 'lab_users#add_users', via: [:get, :post]
  match 'add_users', :to=> 'lab_users#add_users', via: [:get, :post]
  
  match 'vms_by_lab', :to=>'vms#vms_by_lab', via: [:get, :post]
  match 'vms_by_lab/:id', :to=>'vms#vms_by_lab', via: [:get, :post]
  match 'vms_by_state', :to=>'vms#vms_by_state', via: [:get, :post]
  match 'vms_by_state/:state', :to=>'vms#vms_by_state', via: [:get, :post]
  
  match 'my_labs/:id/:username', :to => 'labs#user_labs', via: [:get, :post]
  match 'my_labs/:id', :to => 'labs#user_labs', via: [:get, :post]
  match 'my_labs', :to =>'labs#user_labs', via: [:get, :post]

  match 'open_guacamole', :to=>'vms#open_guacamole', via: [:get, :post]
  match 'open_guacamole/:id', :to=>'vms#open_guacamole' , via: [:get, :post]

  match 'send_keys', :to=>'vms#send_keys', via: [:post]
  match 'send_text', :to=>'vms#send_text', via: [:post]

  match 'user_labs/:username', :to=>'labs#user_labs', via: [:get, :post]
  match 'user_labs/:username/:id', :to => 'labs#user_labs', via: [:get, :post]

  
  match 'not_found', :to=>"home#error_404", via: [:get, :post]

  # You can have the root of your site routed with "root"
  root 'home#index'

  # This is a catch-all for routes that don't exist, visitor is redirected to home page.
  #ActionController::Routing::Routes.draw do |map|
  #    map.connect ':controller/:action/:id'
  #    map.connect '*path', :controller => 'home', :action => 'catcher'
  #end
  match ':controller/:action/:id',  :to=>'home#catcher' , via: [:get, :post, :delete]
  match '*path',  :to=>'home#catcher', via: [:get, :post, :delete]

end
