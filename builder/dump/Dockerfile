FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y wget gnupg2
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y postgresql-12

# RUN echo "$DB_HOSTNAME:$PORT:$DATABASE:$USERNAME:$PASSWORD" > ~/.pgpass
# RUN chmod 600 ~/.pgpass
RUN apt-get install ca-certificates zip
RUN mkdir /usr/local/share/ca-certificates/ssm
RUN chmod 755 /usr/local/share/ca-certificates/ssm
COPY ./ssm.crt /usr/local/share/ca-certificates/ssm
RUN chmod 644 /usr/local/share/ca-certificates/ssm/ssm.crt
RUN update-ca-certificates

COPY ./dump.sh /usr/bin
RUN chmod 777 /usr/bin/dump.sh
COPY ./import.sh /usr/bin
RUN chmod 777 /usr/bin/import.sh

CMD '/bin/bash'
