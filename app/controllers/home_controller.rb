class HomeController < ActionController::Base
  layout 'application'

  def root
    # Client-side redirect logic handled by JavaScript
    # For server-side preference: could check JWT validity here
    render 'home/root'
  end

  def login
    # Render login page (sessions/new.html.erb)
    render 'sessions/new'
  end

  def index
    # Render home page with rewards (home/index.html.erb)
    # Stateless - no server-side validation needed
    # Client-side JavaScript checks for JWT in localStorage
  end
end
