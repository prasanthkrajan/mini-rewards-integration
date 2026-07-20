class HomeController < ActionController::Base
  layout 'application'

  def root
    render 'home/root'
  end

  def login
    render 'sessions/new'
  end

  def index
    render 'home/index'
  end
end
