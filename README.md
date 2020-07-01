# docker.typo3-v10-webserver

This repository extends [mattrayner's lamp](https://github.com/mattrayner/docker-lamp) with stuff to use for typo3 websites.

This Dockerfile is all I have done:

``` sh
FROM mattrayner/lamp:latest-1804

RUN apt-get update \
        && apt-get install -y --no-install-recommends \
# Install PHP Extensions
        php-intl \
# Install required 3rd party tools
        graphicsmagick nodejs npm

# Install gulp cli globally
RUN npm install gulp-cli -g

# adjust php settings
RUN echo 'always_populate_raw_post_data = -1\nmax_execution_time = 240\nmax_input_vars = 1500\nupload_max_filesize = 32M\npost_max_size = 32M\nxdebug.max_nesting_level = 400' > /etc/php/7.4/mods-available/typo3.ini \
    && cd /etc/php/7.4/apache2/conf.d \
    && ln -s /etc/php/7.4/mods-available/typo3.ini

# Change document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

CMD ["/run.sh"]
```

With this image you can easily install typo3 (or other AMP stuff) and start working. Just follow the steps below.

## Installation

### 0. Before starting

Create folder structure:

``` sh
mkdir my-new-website.tld
cd my-new-website.tld
mkdir app
mkdir mysql
```

### 1. Start the container

``` sh
docker run -i -t -d -p "80:80" -v ${PWD}/app:/app -v ${PWD}/mysql:/var/lib/mysql --name my-new-website.tld sunixzs/typo3-v10-webserver
```

Or if you build your own image the name is another:

``` sh
docker run -i -t -d -p "80:80" -v ${PWD}/app:/app -v ${PWD}/mysql:/var/lib/mysql --name my-new-website.tld my_docker_name/my_repository_name
```

### 2. Copy composer.json and compose

Create a project  matching `composer.json` on https://get.typo3.org/misc/composer/helper or copy the following into `app/composer.json`:

``` js
{
    "repositories": [
        {
            "type": "composer",
            "url": "https://composer.typo3.org/"
        }
    ],
    "name": "typo3/cms-base-distribution",
    "description" : "TYPO3 CMS Base Distribution",
    "license": "GPL-2.0-or-later",
    "config": {
        "platform": {
            "php": "7.4"
        }
    },
    "require": {
        "typo3/minimal": "^10.4",
        "typo3/cms-scheduler": "^10.4",
        "typo3/cms-fluid-styled-content": "^10.4",
        "typo3/cms-recycler": "^10.4",
        "typo3/cms-reports": "^10.4",
        "typo3/cms-setup": "^10.4",
        "typo3/cms-rte-ckeditor": "^10.4",
        "typo3/cms-about": "^10.4",
        "typo3/cms-belog": "^10.4",
        "typo3/cms-beuser": "^10.4",
        "typo3/cms-felogin": "^10.4",
        "typo3/cms-impexp": "^10.4",
        "typo3/cms-info": "^10.4",
        "typo3/cms-lowlevel": "^10.4",
        "typo3/cms-redirects": "^10.4",
        "typo3/cms-seo": "^10.4",
        "typo3/cms-sys-note": "^10.4",
        "typo3/cms-t3editor": "^10.4",
        "typo3/cms-tstemplate": "^10.4",
        "typo3/cms-viewpage": "^10.4",
        "erusev/parsedown": "^1.7",
        "typo3/cms-filemetadata": "^10.4",
        "friendsoftypo3/sys-action": "^10.0.0",
        "gridelementsteam/gridelements": "^10.0",
        "helhum/typo3-console": "^6.1"
    },
    "extra": {
        "typo3/cms": {
            "web-dir": "public"
        }
    }
}

```

Then log in into the container and compose:

``` sh
docker exec -t -i my-new-website.tld bash
cd /app
composer update
```

Maybe go and get some coffee while composer loads and loads and loads...  
... then, we are already on the server, create `FIRST_INSTALL`:

``` sh
touch public/FIRST_INSTALL
```

### 3. Create a database and user

**Possibility 1:** Leave the shell in step 2 and create with `docker exec`.

``` sh
docker exec {{DOCKER_CONTAINER_NAME}} mysql -uroot -e "CREATE DATABASE ${DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
docker exec {{DOCKER_CONTAINER_NAME}} mysql -uroot -e "CREATE USER '{{DB_USER}}'@'%' IDENTIFIED BY '{{DB_PASSWORD}}'"
docker exec {{DOCKER_CONTAINER_NAME}} mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '{{DB_USER}}'@'%'"
```

**Possibility 2:** Use the shell in step 2 and log into mysql: `mysql -uroot`.

``` mysql
CREATE DATABASE {{DATABASE}} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER '{{DB_USER}}'@'%' IDENTIFIED BY '{{DB_PASSWORD}}';
GRANT ALL PRIVILEGES ON *.* TO '{{DB_USER}}'@'%'
```

All marked with `{{VAR}}` you have to replace with your stuff:

* `{{DOCKER_CONTAINER_NAME}}` is the name of your container which you set above in step 1 with parameter `--name`
* `{{DATABASE}}` Name of the mysql database to use
* `{{DB_USER}}` Mysql user
* `{{DB_PASSWORD}}` Mysql password

### 4. Open a Browser, type [`http://localhost`](http://localhost) and start typo3 install tool

Follow the white rabbit (in install tool).

### 5. Test and setup typo3

After log in into the backend:

* Set some presets in module `Settings` -> `Choose Presets`
    * `Debug settings` -> `Debug`
    * `Image handling settings` -> `Graphics Magick`
* Check database in module `Maintenance` -> `Analyze database`
* Check filesystem in module `Environment` -> `Directory Status`
* Check php in module `Environment` -> `Environment Status`
* `Maintenance` -> `Flush cache`
* Check frontend: [`http://localhost`](http://localhost)
* Don't tell your boss setting up a webserver with apache/mysql/php and doing a basic typo3 installation is so quick.  
Better lean back and drink another cup of coffee.
