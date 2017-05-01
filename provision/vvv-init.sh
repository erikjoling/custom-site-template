#!/usr/bin/env bash
# Provision WordPress Stable

DOMAIN=`get_primary_host "${VVV_SITE_NAME}".dev`
DOMAINS=`get_hosts "${DOMAIN}"`
SITE_TITLE=`get_config_value 'site_title' "${DOMAIN}"`
WP_VERSION=`get_config_value 'wp_version' 'latest'`
WP_TYPE=`get_config_value 'wp_type' "single"`
DB_NAME=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}

# Make a database, if we don't already have one
echo -e "\nCreating database '${DB_NAME}' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Nginx Logs
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/error.log
touch ${VVV_PATH_TO_SITE}/log/access.log

# Install and configure the latest stable version of WordPress
if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-load.php" ]]; then
    echo "Downloading WordPress..."
  noroot wp core download --version="${WP_VERSION}"
fi

if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-config.php" ]]; then
  echo "Configuring WordPress Stable..."
  noroot wp core config --dbname="${DB_NAME}" --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
/** For developers: WordPress debugging mode. */
define( 'WP_DEBUG', true );
define( 'SAVEQUERIES', false ); // Only activate when researching

/** Extra debugging */
if (WP_DEBUG) {
  define('SCRIPT_DEBUG', true);
  define('WP_DEBUG_LOG', true);
}
PHP
fi

if ! $(noroot wp core is-installed); then

  ### WORDPRESS CORE ###

  echo "Installing WordPress Stable..."

  if [ "${WP_TYPE}" = "subdomain" ]; then
    INSTALL_COMMAND="multisite-install --subdomains"
  elif [ "${WP_TYPE}" = "subdirectory" ]; then
    INSTALL_COMMAND="multisite-install"
  else
    INSTALL_COMMAND="install"
  fi

  noroot wp core ${INSTALL_COMMAND} --url="${DOMAIN}" --quiet --title="${SITE_TITLE}" --admin_name=admin --admin_email="admin@local.dev" --admin_password="password"


  ### THEME ###

  # Install and activate EJO Starter Theme
  git clone https://github.com/erikjoling/ejo-starter-theme.git ${VVV_PATH_TO_SITE}/public_html/wp-content/themes/ejo-starter-theme
  noroot wp theme activate ejo-starter-theme

  # Remove default themes
  noroot wp theme uninstall twentyfifteen twentysixteen twentyseventeen


  ### PLUGINS ### 

  # Remove default plugins
  noroot wp plugin uninstall hello akismet

  # Download GitHub Updater (without gitconfig stuff)

  # Install common plugins
  noroot wp plugin install wordpress-seo gravityformscli regenerate-thumbnails disable-emojis wp-comment-humility safe-redirect-manager carbon-fields
  
  # Install Gravity Forms (license key is required either in the GF_LICENSE_KEY constant or the --key option.)
  # noroot wp gf install -key=xxxxx

  # Install EJO Base
  git clone https://github.com/erikjoling/ejo-base.git ${VVV_PATH_TO_SITE}/public_html/wp-content/plugins/ejo-base

  # Activate the plugins
  noroot wp plugin activate wordpress-seo gravityformscli regenerate-thumbnails disable-emojis wp-comment-humility safe-redirect-manager carbon-fields ejo-base


  ### OTHER ###
 
  # Remove default Widgets from sidebars
  noroot wp widget delete recent-comments-2 search-2 recent-posts-2 archives-2 categories-2 meta-2

  # Import default content
  # Timezone?
  # Subtitle?
  # Permalink settings?

else
  echo "Updating WordPress Stable..."
  cd ${VVV_PATH_TO_SITE}/public_html
  noroot wp core update --version="${WP_VERSION}"
fi

cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
sed -i "s#{{DOMAINS_HERE}}#${DOMAINS}#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
