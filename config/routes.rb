ITee::Application.routes.draw do

  match 'jobs',:to=> 'home#jobs'
  match 'jobs/:id', :to=>'home#delete_job', via: [:delete]
  match 'jobs/:id', :to=>'home#run_job', via: [:put]

  match 'networks/:id/edit', :to => 'networks#index'
  resources :lab_vmt_networks

  resources :networks

  resources :user_badges

  resources :lab_badges

  resources :badges

  resources :operating_systems

  match 'users/sign_up', :to=>'home#catcher'
  
  resources :lab_users
  match 'lab_users', :to=>'lab_users#destroy', via: [:delete]
  match 'lab_users', :to=>'lab_users#update', via: [:put]

 
  resources :lab_vmts

  resources :vmts

  devise_for :users,  :controllers => {:registrations => 'users/registrations', :passwords=> 'users/passwords'}

  #match 'users/edit', :to=>'devise/registrations#edit'

  resources :users
  match 'users/:id', :to=>'users#destroy', via: [:delete]
  match 'users', :to=>'users#destroy', via: [:delete]
  match 'users', :to=>'users#update', via: [:put]

  resources :vms

  resources :materials
  
  resources :labs
  match 'labs', :to=>'labs#destroy', via: [:delete]
  match 'labs', :to=>'labs#update', via: [:put]

  resources :hosts

  resources :token_authentications, :only => [:update, :destroy]

  # route, :to => 'controller#action'
  
  match 'search', :to=> 'lab_users#search'


  match 'lab_users/import', :to=>'lab_users#import'
  match 'manage_tokens', :to=>'lab_users#user_token'
  match 'edit_token', :to=>'token_authentications#edit'
  match 'edit_token/:id', :to=>'token_authentications#edit'
  
  match 'users/edit', :to=>'users#edit'
  match 'users/edit/:id', :to=>'users#edit'

  match 'error_401', :to => 'home#error_401'
  match 'template', :to => 'home#template'
  match 'system', :to => 'home#system'
  match 'about', :to=> 'home#about'
  match 'getprogress', :to=> 'home#getprogress'
  #with user
  match 'start_all/:id/:username', :to=> 'vms#start_all'
  match 'stop_all/:id/:username', :to=> 'vms#stop_all'
  #with id
  match 'start_all/:id', :to=> 'vms#start_all'
  match 'stop_all/:id', :to=> 'vms#stop_all'

  match 'start_vm/:id', :to=> 'vms#start_vm'
  match 'init_vm/:id', :to=> 'vms#init_vm'
  match 'pause_vm/:id', :to=> 'vms#pause_vm'
  match 'resume_vm/:id', :to=> 'vms#resume_vm'
  match 'stop_vm/:id', :to=> 'vms#stop_vm'
  match 'rdp_reset/:id', :to=> 'vms#rdp_reset'

  match 'state_of', :to=> 'vms#get_state'
  match 'rdp_of', :to=> 'vms#get_rdp'
  match 'rdp_reset', :to=> 'vms#rdp_reset'
  
  match 'set_progress', :to=> 'vms#set_progress'
  match 'vms/get_progress/:id', :to=> 'vms#get_progress'
    #no id
  match 'start_all', :to=> 'vms#start_all'
  match 'stop_all', :to=> 'vms#stop_all'
  match 'start_all_by_id', :to=> 'vms#start_all_by_id'
  match 'stop_all_by_id', :to=> 'vms#stop_all_by_id'
  match 'labuser_vms', :to=> 'vms#labuser_vms'

  match 'start_vm', :to=> 'vms#start_vm'
  match 'init_vm', :to=> 'vms#init_vm'
  match 'pause_vm', :to=> 'vms#pause_vm'
  match 'resume_vm', :to=> 'vms#resume_vm'
  match 'stop_vm', :to=> 'vms#stop_vm'
  
  match 'end_lab/:id', :to=>'labs#end_lab'
  match 'end_lab', :to=>'labs#end_lab'

  match 'start_lab/:id/:username', :to=>'labs#start_lab'
  match 'start_lab/:id', :to=>'labs#start_lab'
  match 'start_lab', :to=>'labs#start_lab'

  match 'start_lab_by_id', :to=> 'labs#start_lab_by_id', via: [:post]
  match 'end_lab_by_id', :to=> 'labs#end_lab_by_id', via: [:post]
  match 'restart_lab_by_id', :to=> 'labs#restart_lab_by_id', via: [:post]

  match 'restart_lab/:id/:username', :to=> 'labs#restart_lab'
  match 'restart_lab/:id', :to=> 'labs#restart_lab'
  match 'restart_lab', :to=> 'labs#restart_lab'

  match 'add_users/:id', :to=> 'lab_users#add_users'
  match 'add_users', :to=> 'lab_users#add_users'
  match 'lab_users/progress/:id', :to=> 'lab_users#progress'
  
  match 'vms_by_lab', :to=>'vms#vms_by_lab'
  match 'vms_by_lab/:id', :to=>'vms#vms_by_lab'
  match 'vms_by_state', :to=>'vms#vms_by_state'
  match 'vms_by_state/:state', :to=>'vms#vms_by_state'
  
  match 'my_labs/:id/:username', :to => 'labs#user_labs'
  match 'my_labs/:id', :to => 'labs#user_labs'
  match 'my_labs', :to =>'labs#user_labs'

  match 'user_labs/:username', :to=>'labs#user_labs'
  match 'user_labs/:username/:id', :to => 'labs#user_labs'

  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
   root :to => 'home#index'

  
  # This is a catch-all for routes that don't exist, visitor is redirected to home page.
  #ActionController::Routing::Routes.draw do |map|
#    map.connect ':controller/:action/:id'
#    map.connect '*path', :controller => 'home', :action => 'catcher'
#end
match ':controller/:action/:id',  :to=>'home#catcher' 
match '*path',  :to=>'home#catcher'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
