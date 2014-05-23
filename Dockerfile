FROM ubuntu:14.04
MAINTAINER Tim Riley <tim@icelab.com.au>

# Add repository for Postgres 9.3. This PGP key should match
# https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN locale-gen en_US.UTF-8
RUN apt-get update
RUN LC_ALL=en_US.UTF-8 DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install \
      python-software-properties \
      software-properties-common \
      libpq-dev \
      postgresql-9.3 \
      postgresql-client-9.3 \
      postgresql-contrib-9.3 \
      sudo

# /etc/ssl/private can't be accessed from within container for some reason
# (@andrewgodwin says it's something AUFS related)
RUN mkdir /etc/ssl/private-copy; \
    mv /etc/ssl/private/* /etc/ssl/private-copy/; \
    rm -r /etc/ssl/private; \
    mv /etc/ssl/private-copy /etc/ssl/private; \
    chmod -R 0700 /etc/ssl/private; chown -R postgres /etc/ssl/private

# Recreate the cluster to be UTF8
RUN service postgresql stop && \
    pg_dropcluster --stop 9.3 main && \
    pg_createcluster -e UTF8 9.3 main

ADD postgresql.conf /etc/postgresql/9.3/main/postgresql.conf
ADD pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf
ADD run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

VOLUME ["/var/lib/postgresql"]
EXPOSE 5432
CMD ["/usr/local/bin/run"]
