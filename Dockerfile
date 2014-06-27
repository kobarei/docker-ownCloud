FROM centos

MAINTAINER Reiji Kobayashi

EXPOSE 80

# yum update
RUN yum -y update

# Install wget vim
RUN yum -y install wget vim

# epel
RUN rpm -Uvh http://ftp-srv2.kddilabs.jp/Linux/distributions/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm

# Install Owncloud
RUN cd /etc/yum.repos.d/ && wget http://download.opensuse.org/repositories/isv:ownCloud:community/CentOS_CentOS-6/isv:ownCloud:community.repo
RUN yum -y install owncloud

# Apache
RUN chown -R apache:apache /var/www/html && chmod 755 /var/www/html
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
