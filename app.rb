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

def create_membership(user_id, meetup_id)
  @my_membership = Membership.create(user_id: user_id, meetup_id: meetup_id)
end

def create_comment(user_id, meetup_id, title = nil, body)
  @my_comment = Comment.create(user_id: user_id, meetup_id: meetup_id, title: title, body: body)
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
  @membership = @meetup.memberships.find_by(user: current_user)
  @comments = Comment.where(meetup_id: params[:id])
  erb :views
end

post '/meetup/:meetup_id/comment' do
  if signed_in? && Membership.find_by(user_id: session[:user_id], meetup_id: params[:meetup_id]) != nil
    create_comment(session[:user_id], params[:meetup_id], params[:title], params[:body])
    redirect "meetup/#{params[:meetup_id]}"
  else
    flash[:notice] = "You must be signed in and a member of this meetup to post a comment!"
    redirect "meetup/#{params[:meetup_id]}"
  end
end

post '/meetup/:meetup_id/memberships' do
  if signed_in?
    create_membership(session[:user_id], params[:meetup_id])
    flash[:notice] = "You've joined this meetup!"
    redirect "/meetup/#{params[:meetup_id]}"
  else
    authenticate!
  end
end

delete '/memberships/:membership_id' do
  Membership.find_by(id: params[:membership_id]).destroy
  flash[:notice] = "You've left this meetup!"
  redirect "/meetups/list"
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
