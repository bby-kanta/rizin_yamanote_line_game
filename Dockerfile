FROM ruby:3.3-alpine

RUN apk add --no-cache \
    build-base \
    mariadb-dev \
    nodejs \
    yarn \
    tzdata \
    yaml-dev \
    git

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]