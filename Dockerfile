FROM mattrayner/lamp:latest-1804

RUN apt-get update \
        && apt-get install -y --no-install-recommends \
# Install PHP Extensions
        php-intl \
# Install required 3rd party tools
        graphicsmagick nodejs npm

# adjust php settings
RUN echo 'always_populate_raw_post_data = -1\nmax_execution_time = 240\nmax_input_vars = 1500\nupload_max_filesize = 32M\npost_max_size = 32M\nxdebug.max_nesting_level = 400' > /etc/php/7.4/mods-available/typo3.ini \
    && cd /etc/php/7.4/apache2/conf.d \
    && ln -s /etc/php/7.4/mods-available/typo3.ini

# Change document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

CMD ["/run.sh"]
