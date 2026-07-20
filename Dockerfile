FROM ruby:3.4.3
WORKDIR /app
RUN apt-get update && apt-get install -y postgresql-client
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
EXPOSE 3000
CMD ["sh", "-c", "rails db:create db:migrate db:seed && rails server -b 0.0.0.0"]