#!/usr/bin/env bash
# Provision WordPress Stable

 # fetch the first host as the primary domain. If none is available, generate a default using the site name 
DOMAIN=`get_primary_host "${VVV_SITE_NAME}".test`

# Get the site title specified in vvv-custom.yml. Fallback: DOMAIN value
SITE_TITLE=`get_config_value 'site_title' "${DOMAIN}"`

# Get the WordPress version specified in vvv-custom.yml. Fallback: latest version
WP_VERSION=`get_config_value 'wp_version' 'latest'`

# Get the type of WP install (single/subdomain) specified in vvv-custom.yml. Fallback: Single
WP_TYPE=`get_config_value 'wp_type' "single"`

# Get the database name specified in vvv-custom.yml. Fallback: site-name
DB_NAME=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}

# cd ${VVV_PATH_TO_SITE}/public_html

#
# DATABASE
#

echo -e "\nStep 1: Database."

if ( ! $(noroot wp core is-installed) ); then
    echo -e "\nWordPress is not installed. Create database."

    # Make a database, if we don't already have one
    echo -e "\nCreating database '${DB_NAME}' (if it's not already there)"
    mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
    mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"
    echo -e "\n DB operations done.\n\n"

else
    echo -e "\nWordPress is already installed. Continue."
fi

#
# WORDPRESS CORE
#

echo -e "\nStep 2: WordPress Core."

# If WordPress is not already installed:
# Download, setup wp-config and install the latest stable version of WordPress

# Download
if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-load.php" ]]; then
    echo -e "\nCould not find WordPress in '${VVV_PATH_TO_SITE}/public_html/'. Download WordPress Core."
    echo "Downloading WordPress..."
    noroot wp core download --version="${WP_VERSION}" --locale=nl_NL
fi

# Setup wp-config
if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-config.php" ]]; then
    echo -e "\nCould not find wp-config.php in '${VVV_PATH_TO_SITE}/public_html/'. Set up wp-config.php."
    echo "Setting up WordPress Config..."
    noroot wp core config --dbname="${DB_NAME}" --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
/**
 * CUSTOM 
 */

/** Main debug setting */
define( 'WP_DEBUG', true );

if (WP_DEBUG) {
    define('SCRIPT_DEBUG', true);
    define('WP_DEBUG_LOG', true);
}

/** Only activate when researching (heavy on resources) */
define( 'SAVEQUERIES', false );

/** Limit post revisions to 5 at max */
define( 'WP_POST_REVISIONS', 5 );

/** Don't allow file editing from inside WordPress */
define('DISALLOW_FILE_EDIT', true);

/**
 * END CUSTOM
 */
PHP
fi

# Install
if ( ! $(noroot wp core is-installed) ); then

    echo -e "\nWordPress is not installed. Install WordPress."

    ### WORDPRESS CORE ###

    echo "Installing WordPress Stable..."

    if [ "${WP_TYPE}" = "subdomain" ]; then
        INSTALL_COMMAND="multisite-install --subdomains"
    elif [ "${WP_TYPE}" = "subdirectory" ]; then
        INSTALL_COMMAND="multisite-install"
    else
        INSTALL_COMMAND="install"
    fi

    noroot wp core ${INSTALL_COMMAND} --url="${DOMAIN}" --quiet --title="${SITE_TITLE}" --admin_name=admin --admin_email="erik@ejoweb.nl" --admin_password="password"

    ##
    # PLUGINS
    ##

    # Remove default plugins
    noroot wp plugin uninstall hello akismet

    # Install common plugins
    noroot wp plugin install wordpress-seo regenerate-thumbnails wp-comment-humility safe-redirect-manager --activate

    ##
    # THEME
    ##

    # Remove default themes
    noroot wp theme uninstall twentyfifteen twentysixteen twentyseventeen

    ##
    # OTHER
    ##
 
    # Remove default Widgets from sidebars
    noroot wp widget delete recent-comments-2 search-2 recent-posts-2 archives-2 categories-2 meta-2
fi

#
# NGINX
#

echo -e "\nStep 3: NGINX."

# Nginx Logs
echo "Setting up logs..."
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/error.log
touch ${VVV_PATH_TO_SITE}/log/access.log

# Nginx Configuration
echo "Setting up configuration..."
cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"

# SSL/TLS
echo "Setting up ssl/tls..."
if [ -n "$(type -t is_utility_installed)" ] && [ "$(type -t is_utility_installed)" = function ] && `is_utility_installed core tls-ca`; then
    sed -i "s#{{TLS_CERT}}#ssl_certificate /vagrant/certificates/${VVV_SITE_NAME}/dev.crt;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    sed -i "s#{{TLS_KEY}}#ssl_certificate_key /vagrant/certificates/${VVV_SITE_NAME}/dev.key;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
else
    sed -i "s#{{TLS_CERT}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    sed -i "s#{{TLS_KEY}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
fi
