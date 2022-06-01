FROM ubuntu:18.04

WORKDIR /app
ENV MIX_ENV=prod
ENV LANG="en_US.UTF-8"

#install wget
RUN apt-get update && apt-get -y upgrade && apt-get install -y wget curl locales gnupg
RUN locale-gen en_US.UTF-8 && update-locale
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
    dpkg -i erlang-solutions_1.0_all.deb

#install Erlang & Elixir
RUN apt-get update && apt-get install -y esl-erlang elixir git openssh-server build-essential
RUN mix local.hex --force && mix local.rebar --force

#install node
RUN curl -sL https://deb.nodesource.com/setup_15.x | bash -
RUN apt-get install -y nodejs python2.7
#RUN ln -s `which python2.7` /usr/bin/python

#install golang
RUN wget https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz
RUN tar -xvf go1.9.2.linux-amd64.tar.gz
RUN ln -s /app/go/bin/go /usr/local/bin/go
RUN go version

COPY ./compile.sh /usr/bin
RUN chmod 777 /usr/bin/compile.sh

CMD '/bin/bash'
