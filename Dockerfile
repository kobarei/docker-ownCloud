FROM centos

MAINTAINER Reiji Kobayashi

EXPOSE 80 443

# yum update
RUN yum update -y

# Set Locale
RUN echo LANG="en_US.UTF-8" > /etc/sysconfig/i18n
RUN source /etc/sysconfig/i18n

# Install [wget, vim]
RUN yum install -y wget vim

# Add repos [epel, remi, owncloud, nginx]
RUN rpm -Uvh http://ftp-srv2.kddilabs.jp/Linux/distributions/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
RUN \
  curl -L0 http://download.opensuse.org/repositories/isv:ownCloud:community/CentOS_CentOS-6/isv:ownCloud:community.repo > \
  /etc/yum.repos.d/isv:ownCloud:community.repo
ADD yum.repos.d/nginx.repo /etc/yum.repos.d/nginx.repo

# Install ownCloud
RUN yum install -y --enablerepo=remi owncloud

# Install and Configure nginx
RUN yum install -y --enablerepo=nginx nginx
RUN rm -rf /etc/nginx/conf.d/default.conf
ADD nginx/nginx.conf    /etc/nginx/nginx.conf
ADD nginx/owncloud.conf /etc/nginx/conf.d/owncloud.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Move ownCloud path
RUN chown nginx. -R /var/www/html/owncloud
RUN mv /var/www/html/owncloud /usr/share/nginx/owncloud

# Install and Configure php-fpm
RUN yum install -y --enablerepo=remi php-fpm
RUN \
  cat /etc/php-fpm.d/www.conf | \
  sed -i \
    -e "s/127\.0\.0\.1\:9000/\/var\/run\/php-fpm\/php-fpm\.sock/" \
    -e "s/\;listen\.owner/listen\.owner/" \
    -e "s/\;listen\.group/listen\.group/" \
    -e "s/\;listen\.mode/listen\.mode/" \
    -e "s/nobody/nginx/g" \
    -e "s/0660/0666/g" \
    -e "s/apache/nginx/g" \
  /etc/php-fpm.d/www.conf

# Install and Configure supervisor
RUN yum install -y --enablerepo=epel supervisor
ADD supervisor/supervisord.conf /etc/supervisord.conf

# Start supervisor
CMD /usr/bin/supervisord
