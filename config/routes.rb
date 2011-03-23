ITee::Application.routes.draw do
  
  
  resources :lab_users

  resources :lab_vmts

  resources :vmts

  resources :lab_materials

  devise_for :users


  resources :vms

  resources :materials

  resources :labs

  resources :hosts


  # route, :to => 'controller#action'
  
  
  match 'error_401', :to => 'home#error_401'
  
    match 'init_vm/:id', :to=> 'vms#init_vm'
    match 'pause_vm/:id', :to=> 'vms#pause_vm'
    match 'resume_vm/_id', :to=> 'vms#resume_vm'
    match 'stop_vm/:id', :to=> 'vms#stop_vm'
  
  match 'end_lab/:id', :to=>'labs#end_lab'
  match 'running_lab/:id', :to=> 'labs#running_lab'
  match 'running_lab', :to=> 'labs#running_lab'
  match 'add_users', :to=> 'lab_users#add_users'
  match 'profile', :to=>'home#profile'
  
  match 'courses/:id', :to => 'labs#courses'
  match 'courses', :to =>'labs#courses'

  
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

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
