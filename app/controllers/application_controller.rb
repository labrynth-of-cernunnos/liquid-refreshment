require 'active_record'

class ApplicationController < Sinatra::Base

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    register Sinatra::ActiveRecordExtension
    enable :sessions
    register Sinatra::Flash
    set :session_secret, 'dummySessionSecret'
  end

  get '/' do
    if logged_in?
      redirect '/beers'
    else
      redirect '/login'
    end
  end

  get '/signup' do
    if logged_in?
      user = User.find_by(id: session[:user_id])
      redirect "/users/#{user.slug}/beers"
    else
      erb :'/sessions/signup'
    end
  end

  post '/signup' do
    user = User.new(params)
    if user.valid? && user.errors.empty?
      user.save
      login(params[:email], params[:password])
      flash[:success] = "Welcome, #{user.username.capitalize}! \n Let's drink some Beer!"
      redirect "/users/#{user.slug}/beers"
    else
      flash[:error] = user.errors.full_messages
      redirect '/signup'
    end
  end

  get '/login' do
    if !logged_in?
      erb :'/sessions/login'
    else
      redirect '/beers'
    end
  end

  post '/login' do
    login(params[:email], params[:password])
    user = User.find_by(email: params[:email])
    flash[:success] = "Let's drink some beer, #{user.username.capitalize}!"
    redirect "/users/#{user.slug}/beers"
  end

  get '/logout' do
    logout!
    redirect '/login'
  end

  helpers do
    def logged_in?
      !!session[:user_id]
    end

    def login(email, password)
      user  = User.find_by(email: email)
      if user && user.authenticate(password)
        #is this safe to expose via cookie?
        session[:user_id] = user.id
      else
        flash[:error] = ["Invalid Credientals"]
        redirect '/login'
      end
    end

    def logout!
      session.clear
    end

    def build_slug
      user = User.find_by(id: session[:user_id])
      user ? user.slug : nil
    end

    def active_page?(path)
      request.path_info == path
    end

    def access_denied
      flash[:error] = ["Access Denied"]
      redirect '/login'
    end

    def overall_rating(beer)
      if beer.opinions.blank?
        "No Raitings Yet"
      else
        "#{beer.opinions.average(:user_rating).to_f.round(1)} out of #{beer.opinions.length}"
      end
    end

  end
end
