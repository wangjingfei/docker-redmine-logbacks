FROM ubuntu:14.04
MAINTAINER wangjingfei@irenshi.cn

ENV VERSION 1.0

RUN echo "deb http://cn.archive.ubuntu.com/ubuntu/ trusty main universe multiverse restricted" > /etc/apt/sources.list
RUN echo "deb http://cn.archive.ubuntu.com/ubuntu/ trusty-updates main universe multiverse restricted" >> /etc/apt/sources.list
RUN apt-get update

## Change the timezone
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN apt-get install ntpdate && ntpdate cn.pool.ntp.org

## Install necessay requirements for gem and bundler
RUN apt-get install openssl libssl-dev libmysqlclient-dev -y

## Environments
ENV RUBY_VERSION 2.0.0-p481
ENV RUBY_TAR_FILE ruby-${RUBY_VERSION}.tar.gz
ENV RUBY_DIRECTORY ruby-${RUBY_VERSION}
ENV REDMINE_VERSION 2.3.2
ENV REDMINE_TAR_FILE redmine-${REDMINE_VERSION}.tar.gz
ENV REDMINE_HOME /opt/redmine-${REDMINE_VERSION}
ENV LOGBACKS_VERSION 1.0.6
ENV LOGBACKS_TAR_FILE redmine_backlogs-${LOGBACKS_VERSION}.tar.gz
ENV LOGBACKS_DIRECTORY redmine_backlogs

## Install ruby and gem
COPY $RUBY_TAR_FILE /tmp/
RUN cd /tmp/ && set -x && \
	apt-get install gcc g++ make libxslt-dev libxml2-dev -y && \
	tar -xvf $RUBY_TAR_FILE && \
	cd $RUBY_DIRECTORY && \
	./configure --disable-install-doc && make -j 3 && make install && \
	## For Chinese users who are behinde the Great Fire Wall.
	gem sources --add http://gems.ruby-china.org/ --remove https://rubygems.org/ && \
	gem install bundler && \
	bundle config mirror.https://rubygems.org http://gems.ruby-china.org && \
	#apt-get purge -y --auto-remove gcc make && \
	rm -rf $RUBY_DIRECTORY
		
## Install redmine. The version has to be 2.3.2, no else.
COPY $REDMINE_TAR_FILE /opt/
RUN cd /opt/ && set -x && \
	tar -xvf $REDMINE_TAR_FILE

ENV RAILS_ENV production
RUN cd $REDMINE_HOME && set -x && \
	gem install mysql2 -v '0.3.21' 
	
## Install redmine backlogs
COPY redmine_backlogs-1.0.6.tar.gz /tmp/
RUN cd /tmp/ && set -x && \
	tar -xvf $LOGBACKS_TAR_FILE && \
	mv $LOGBACKS_DIRECTORY $REDMINE_HOME/plugins/ && \
	rm $LOGBACKS_TAR_FILE && \
	gem install holidays --version 1.0.3 && \
	gem install holidays
ADD config/database.yml $REDMINE_HOME/config/database.yml
RUN cd $REDMINE_HOME && bundle install --without development test rmagick
RUN rm $REDMINE_HOME/config/database.yml
# Prepare the database schema.
RUN rm -rf $REDMINE_HOME/db/schema.rb
ADD db/schema.rb $REDMINE_HOME/db/schema.rb

## Install Apache Web Server
RUN apt-get install apache2 apache2-dev libcurl4-gnutls-dev apache2 libapache2-mod-perl2 libdbd-mysql-perl libauthen-simple-ldap-perl openssl -y

RUN a2enmod ssl && a2enmod perl && a2enmod dav && a2enmod dav_fs && a2enmod rewrite && a2enmod headers

RUN cd $REDMINE_HOME && gem install passenger -v '5.0.28'
RUN passenger-install-apache2-module -a

ADD config/passenger.conf /etc/apache2/conf-available/passenger.conf
ADD config/redmine.conf /etc/apache2/sites-available/redmine.conf

RUN ln -s /etc/apache2/conf-available/passenger.conf /etc/apache2/conf-enabled/passenger.conf
RUN rm -rf /var/www && ln -s $REDMINE_HOME/public /var/www && rm /etc/apache2/sites-enabled/* -rf
RUN ln -s /etc/apache2/sites-available/redmine.conf /etc/apache2/sites-enabled/redmine.conf

## Install supervisor
RUN apt-get install -y supervisor dnsutils
ADD supervisor/*.conf /etc/supervisor/conf.d/

## Clean cached files.
RUN rm -rf /var/lib/apt/lists/*

## Install startup script
ADD scripts/start-apache.sh /opt/start-apache.sh

WORKDIR $REDMINE_HOME

EXPOSE 80

CMD ["supervisord", "-n"]

