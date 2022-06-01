FROM ubuntu:18.04

WORKDIR /app
ENV MIX_ENV=test
ENV LANG="en_US.UTF-8"
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=tester

#install wget
RUN apt-get update && apt-get -y upgrade && apt-get install -y wget curl locales gnupg
RUN locale-gen en_US.UTF-8 && update-locale
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
RUN dpkg -i erlang-solutions_1.0_all.deb

#install Erlang & Elixir
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get install -y esl-erlang elixir git openssh-server build-essential
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y postgresql-12 postgresql-client-12
RUN mix local.hex --force && mix local.rebar --force

#install golang
RUN wget https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz
RUN tar -xvf go1.9.2.linux-amd64.tar.gz
RUN ln -s /app/go/bin/go /usr/local/bin/go
RUN go version

RUN curl -sL https://deb.nodesource.com/setup_15.x | bash -
RUN apt-get install -y nodejs python2.7

RUN apt-get install -y xfonts-75dpi xfonts-base ghostscript
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb
RUN dpkg -i wkhtmltox_0.12.5-1.bionic_amd64.deb
RUN apt install -f

COPY ./test.sh /usr/bin
RUN chmod 777 /usr/bin/test.sh
COPY ./pg_hba.conf /etc/postgresql/12/main

CMD '/bin/bash'
