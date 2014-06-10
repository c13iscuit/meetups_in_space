require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'omniauth-github'
require 'pry'

require_relative 'config/application'

Dir['app/**/*.rb'].each { |file| require_relative file }

helpers do
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id.present?
  end

  def signed_in?
    current_user.present?
  end
end

def set_current_user(user)
  session[:user_id] = user.id
end

def authenticate!
  unless signed_in?
    flash[:notice] = 'You need to sign in if you want to do that!'
    redirect '/'
  end
end

def save_meetup(name, description, location)
  @my_meetup = Meetup.create(name: name, description: description, location: location)
end

get '/' do
  erb :index
end

get '/auth/github/callback' do
  auth = env['omniauth.auth']

  user = User.find_or_create_from_omniauth(auth)
  set_current_user(user)
  flash[:notice] = "You're now signed in as #{user.username}!"

  redirect '/'
end

get '/sign_out' do
  session[:user_id] = nil
  flash[:notice] = "You have been signed out."
  redirect '/'
end

get '/example_protected_page' do
  authenticate!
end

get '/meetup/:id' do
  @meetup = Meetup.find(params[:id])
  erb :views
end

get '/meetups/list' do
  @meetups = Meetup.all
  erb :view_all
end

get '/meetups/create' do
  erb :create_meetup
end

post '/meetups/create' do
  @name = params['name']
  @description = params['description']
  @location = params['location']
  if signed_in?
    save_meetup(@name,@description,@location)
    flash[:notice] = "You've created a meetup called: #{@name}!"
    redirect "meetup/#{@my_meetup.id}"
  else
    authenticate!
  end
end
