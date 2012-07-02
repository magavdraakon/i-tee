ITee::Application.routes.draw do
  resources :operating_systems

  # match 'users/sign_up', :to=>'devise/sessions#new'
  resources :lab_users

  resources :lab_vmts

  resources :vmts

  resources :lab_materials  

  devise_for :users,  :controllers => { :registrations => "users/registrations", :passwords=>"users/passwords" }

  match 'users/edit', :to=>'devise/registrations#edit'
  
  resources :vms

  resources :materials
  
  resources :labs

  resources :hosts

  resources :token_authentications, :only => [:create, :destroy]

  # route, :to => 'controller#action'
  
  match 'lab_users/import', :to=>'lab_users#import'
  match 'manage_tokens', :to=>'lab_users#user_token'
  
  match 'error_401', :to => 'home#error_401'
  match 'template', :to => 'home#template'
  match 'system', :to => 'home#system'
  match 'about', :to=> 'home#about'
  match 'getprogress', :to=> 'home#getprogress'
  #with id
  match 'start_all/:id', :to=> 'vms#start_all'
  match 'start_vm/:id', :to=> 'vms#start_vm'
  match 'init_vm/:id', :to=> 'vms#init_vm'
  match 'pause_vm/:id', :to=> 'vms#pause_vm'
  match 'resume_vm/:id', :to=> 'vms#resume_vm'
  match 'stop_vm/:id', :to=> 'vms#stop_vm'
  match 'set_progress', :to=> 'vms#set_progress'
  match 'vms/get_progress/:id', :to=> 'vms#get_progress'
    #no id
  match 'start_all', :to=> 'vms#start_all'
  match 'start_vm', :to=> 'vms#start_vm'
  match 'init_vm', :to=> 'vms#init_vm'
  match 'pause_vm', :to=> 'vms#pause_vm'
  match 'resume_vm', :to=> 'vms#resume_vm'
  match 'stop_vm', :to=> 'vms#stop_vm'
  
  match 'end_lab/:id', :to=>'labs#end_lab'
  match 'end_lab', :to=>'labs#end_lab'
  match 'restart_lab/:id', :to=> 'labs#restart_lab'
  match 'restart_lab', :to=> 'labs#restart_lab'
  match 'running_labs/:id', :to=> 'labs#running_lab'
  match 'running_labs', :to=> 'labs#running_lab'
  match 'completed_labs/:id', :to=> 'labs#ended_lab'
  match 'completed_labs', :to=> 'labs#ended_lab'
  
  match 'add_users', :to=> 'lab_users#add_users'
  match 'lab_users/progress/:id', :to=> 'lab_users#progress'
  
  match 'vms_by_lab', :to=>'vms#vms_by_lab'
  match 'vms_by_lab/:id', :to=>'vms#vms_by_lab'
  match 'vms_by_state', :to=>'vms#vms_by_state'
  match 'vms_by_state/:state', :to=>'vms#vms_by_state'
  
  match 'all_labs/:id', :to => 'labs#courses'
  match 'all_labs', :to =>'labs#courses'

  
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
   root :to => "home#index"

  
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
