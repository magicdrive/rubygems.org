Rails.application.routes.draw do
  ################################################################################
  # Root

  root :to => 'home#index'

  ################################################################################
  # API v1

  namespace :api do
    namespace :v1 do
      resource :api_key, :only => :show do
        put :reset
      end
      resources :profiles, :only => :show
      resources :downloads, :only => :index do
        get :top, :on => :collection
        get :all, :on => :collection
      end
      constraints :id => Patterns::ROUTE_PATTERN, :format => /json|xml|yaml/ do
        get 'owners/:handle/gems', to: 'owners#gems', as: 'owners_gems', constraints: {handle: Patterns::ROUTE_PATTERN}, format: true

        resources :downloads, only: :show, format: true

        resources :versions, only: :show, format: true do
          member do
            get :reverse_dependencies, format: true
            get 'latest', to: 'versions#latest', as: 'latest', format: true, constraints: {format: /json|js/}
          end

          resources :downloads, only: [:index, :show], controller: 'versions/downloads', format: true do
            collection do
              get :search, format: true
            end
          end
        end
      end

      resources :dependencies, :only => :index

      resources :rubygems, :path => 'gems', :only => [:create, :show, :index], :id => Patterns::LAZY_ROUTE_PATTERN, :format => /json|xml|yaml/ do
        member do
          get :reverse_dependencies
        end
        collection do
          delete :yank
          put :unyank
        end
        constraints :rubygem_id => Patterns::ROUTE_PATTERN do
          resource :owners, :only => [:show, :create, :destroy]
        end
      end

      resource :activity, :only => [], :format => /json|xml|yaml/ do
        collection do
          get :latest
          get :just_updated
        end
      end

      resource :search, :only => :show

      resources :web_hooks, :only => [:create, :index] do
        collection do
          delete :remove
          post :fire
        end
      end
    end
  end

  ################################################################################
  # API v0

  scope :to => 'api/deprecated#index' do
    get 'api_key'
    put 'api_key/reset'

    post 'gems'
    get  'gems/:id.json'

    scope :path => 'gems/:rubygem_id' do
      put  'migrate'
      post 'migrate'
      get    'owners(.:format)'
      post   'owners(.:format)'
      delete 'owners(.:format)'
    end
  end

  ################################################################################
  # UI
  scope constraints: {format: :html}, defaults: {format: 'html'} do
    resource  :search,    :only => :show
    resource  :dashboard, :only => :show, constraints: {format: /html|atom/}
    resources :profiles,  :only => :show
    resource  :profile,   :only => [:edit, :update]
    resources :stats,     :only => :index, :constraints => RecoveryMode

    resources :rubygems, only: [:index, :show, :edit, :update], path: 'gems', constraints: {id: Patterns::ROUTE_PATTERN, format: /html|atom/} do
      resource  :subscription, only: [:create, :destroy], constraints: {format: :js}, defaults: {format: :js}
      resources :versions, only: [:show, :index]
    end
  end

  ################################################################################
  # Clearance Overrides

  resource :session, :only => [:create, :destroy]

  delete '/sign_out' => 'sessions#destroy', as: 'custom_sign_out'

  resources :passwords, :only => [:new, :create]

  resources :users do
    resource :password, :only => [:create, :edit, :update]
  end

end
