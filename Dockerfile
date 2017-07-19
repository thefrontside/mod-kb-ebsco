FROM ruby:2.4.1

RUN apt-get update -qq
RUN mkdir /mod-kb-ebsco
WORKDIR /mod-kb-ebsco
ADD Gemfile /mod-kb-ebsco/Gemfile
ADD Gemfile.lock /mod-kb-ebsco/Gemfile.lock
RUN bundle install
ADD . /mod-kb-ebsco

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
