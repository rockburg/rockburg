require "test_helper"

class AdminAuthenticationTest < ActionController::TestCase
  class DummyController < ApplicationController
    include AdminAuthentication

    allow_unauthenticated_access only: :login

    def index
      render plain: "Admin only"
    end

    def login
      render plain: "Login page"
    end
  end

  tests DummyController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "index" => "admin_authentication_test/dummy#index"
      get "login" => "admin_authentication_test/dummy#login"
      get "session/new" => "admin_authentication_test/dummy#login", as: :new_session
      root to: "admin_authentication_test/dummy#login"
    end
  end

  test "redirects non-admin users to root path" do
    user = users(:two)

    Current.user = user
    Current.session = sessions(:two)
    get :index

    assert_redirected_to root_path
    assert_equal "You don't have permission to access that page", flash[:alert]
  end

  test "allows admin users to access protected pages" do
    user = users(:one)

    Current.user = user
    Current.session = sessions(:one)
    get :index

    assert_response :success
    assert_equal "Admin only", response.body
  end

  test "redirects unauthenticated users to session new" do
    Current.user = nil
    Current.session = nil
    get :index

    assert_redirected_to new_session_path
  end

  teardown do
    Current.user = nil
    Current.session = nil
  end
end
