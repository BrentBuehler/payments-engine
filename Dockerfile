FROM ruby:3.0.0
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
WORKDIR /payments-engine
COPY Gemfile /payments-engine/Gemfile
COPY Gemfile.lock /payments-engine/Gemfile.lock
RUN bundle install

CMD ["rails", "server", "-b", "0.0.0.0"]