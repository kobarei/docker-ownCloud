FROM centos:6.4

MAINTAINER Reiji Kobayashi

EXPOSE 80 443

# yum update
RUN yum update -y

# Install [wget, vim]
RUN yum install -y wget vim

# Add repos [epel, remi, owncloud, nginx]
RUN rpm -Uvh http://ftp-srv2.kddilabs.jp/Linux/distributions/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
RUN \
  curl -L0 http://download.opensuse.org/repositories/isv:ownCloud:community/CentOS_CentOS-6/isv:ownCloud:community.repo > \
  /etc/yum.repos.d/isv:ownCloud:community.repo
ADD yum.repos.d/nginx.repo /etc/yum.repos.d/nginx.repo

# Install ownCloud and php-fpm
RUN yum install -y --enablerepo=remi owncloud php-fpm

# Configure php-fpm
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
    -e "s/\/var\/lib\/php\/session/\/var\/lib\/php\/owncloud\/session/" \
  /etc/php-fpm.d/www.conf

# Install and Configure nginx
RUN yum install -y --enablerepo=nginx nginx
RUN rm -rf /etc/nginx/conf.d/default.conf
ADD nginx/nginx.conf    /etc/nginx/nginx.conf
ADD nginx/owncloud.conf /etc/nginx/conf.d/owncloud.conf

# Move ownCloud path
RUN chown nginx:nginx -R /var/www/html/owncloud
RUN mv /var/www/html/owncloud /usr/share/nginx/owncloud

# Give nginx permissions of ownCloud session path
RUN mkdir -p /var/lib/php/owncloud/session
RUN chown root:nginx -R /var/lib/php/owncloud/session
RUN chmod 770 -R /var/lib/php/owncloud/session

# Install and Configure supervisor
RUN yum install -y --enablerepo=epel supervisor
ADD supervisor/supervisord.conf /etc/supervisord.conf

# Start php-fpm and nginx via supervisor
CMD /usr/bin/supervisord
