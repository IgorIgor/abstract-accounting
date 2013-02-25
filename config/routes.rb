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
  resources :legal_entities do
    collection do
      get 'preview'
      get 'list'
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
      get 'list'
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

  namespace :estimate do
    resources :bo_ms, except: [:destroy] do
      collection do
        get 'preview'
        get 'data'
        get 'find'
      end
    end
    resources :prices, except: [:destroy] do
      collection do
        get 'preview'
        get 'data'
        get 'find'
      end
    end
    resources :catalogs do
      collection do
        get 'data'
        get 'preview'
      end
      member do
        get 'document'
      end
    end
    resources :locals, except: [:destroy] do
      collection do
        get 'data'
        get 'preview'
        get 'load_local_elements'
      end
      member do
        get 'apply'
        get 'cancel'
      end
    end
    resources :projects, except: [:destroy] do
      collection do
        get 'preview'
        get 'data'
      end
    end
  end
end
