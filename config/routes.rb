# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

Abstract::Application.routes.draw do
  root :to => "home#index"
  get "home/index"
  get "inbox" => "home#inbox"
  get "archive" => "home#archive"

  namespace :foreman do
    resources :resources, only:[:index] do
      get 'data', :on => :collection
    end
  end

  resources :helps, only:[:index, :show]
  resources :notifications, only: [:new, :create, :show, :index] do
    collection do
      get 'data'
      get 'preview'
      get 'check'
      post 'hide'
    end
  end

  resources :user_sessions
  get "login" => "user_sessions#new", :as => "login"
  get "logout" => "user_sessions#destroy", :as => "logout"

  resources :password_resets
  resources :estimates do
    collection do
      get 'preview'
    end
  end
  resources :legal_entities do
    collection do
      get 'preview'
    end
  end
  resources :catalogs
  resources :price_lists
  resources :bo_ms do
    member do
      get 'sum'
      get 'elements'
    end
  end
  resources :waybills, except: [:destroy] do
    collection do
      get 'preview'
      get 'data'
      get 'present'
      get 'list'
    end
    member do
      get 'apply'
      get 'cancel'
      get 'reverse'
      get 'resources'
    end
  end
  resources :places do
    collection do
      get 'preview'
      get 'data'
    end
  end
  resources :entities do
    collection do
      get 'data'
      get 'preview'
      get 'autocomplete'
    end
  end
  resources :warehouses, only: [:index] do
    collection do
      get 'data'
      get 'group'
      get 'foremen'
      get 'print'
      get 'report'
    end
  end
  resources :allocations, except: [:destroy] do
    collection do
      get 'preview'
      get 'data'
      get 'list'
    end
    member do
      get 'apply'
      get 'cancel'
      get 'reverse'
      get 'resources'
    end
  end
  resources :general_ledger, only: [:index] do
    collection do
      get 'data'
    end
  end
  resources :balance_sheet, only: [:index] do
    collection do
      get 'data'
      get 'group'
    end
  end
  resources :transcripts, only: [:index] do
    collection do
      get 'preview'
      get 'data'
    end
  end
  resources :deals do
    collection do
      get 'preview'
      get 'data'
      get 'entities'
    end
    member do
      get 'rules'
      get 'state'
    end
  end
  resources :storekeepers, only: [:index]
  resources :users do
    collection do
      get 'preview'
      get 'data'
      get 'names'
    end
  end
  resources :groups do
    collection do
      get 'preview'
      get 'data'
    end
  end
  resources :comments, only: [:create, :index]

  resources :resources, only: :index do
    collection do
      get 'data'
    end
  end
  resources :settings do
    collection do
      get 'preview'
    end
  end
  resources :quote do
    collection do
      get 'data'
      get 'preview'
    end
  end
  resources :assets do
    collection do
      get 'preview'
    end
  end
  resources :money do
    collection do
      get 'preview'
      get 'data'
    end
  end
  resources :countries, only: :index
  resources :facts, only: [:new, :show, :create] do
    collection do
      get 'preview'
    end
  end
  resources :txns

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
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
