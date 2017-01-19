FROM ruby:2.4.0

ENV RACK_ENV production

EXPOSE 5000

COPY . /src
WORKDIR /src
RUN bundle
RUN bundle exec rspec

CMD ["/usr/local/bundle/bin/puma", "-t", "2:16", "-p", "5000"]