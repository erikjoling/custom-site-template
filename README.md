# VVV Custom site template
For when you just need a new WordPress site

- Version: 1.0-beta-6
- Author: Erik Joling <erik@joling.me>

## Overview
This template will allow you to create a WordPress dev environment using only `vvv-custom.yml`.

This is a custom fork of the official VVV custom site template. [See their repo for more documentation](https://github.com/Varying-Vagrant-Vagrants/custom-site-template).

## Todo

### Install with a starter theme

```
# Install starter theme
noroot wp theme install https://github.com/erikjoling/ejo-starter-theme/archive/master.zip --force --activate
```

### GitHub Updater plugin
```
# Install GitHub Updater
noroot wp plugin install https://github.com/afragen/github-updater/archive/master.zip --force --activate
```

### Gravity Forms integration

Define license
```
# Get the gravityforms licence specified in vvv-custom.yml. Fallback: empty string (evaluates to false in [brackets])
GF_KEY=`get_config_value 'gf_licence' ""`
```

Install using license
```
# Install Gravity Forms 
noroot wp plugin install gravityformscli --activate
noroot wp gf install --key="{$GF_KEY}"
```

Other gravity forms configuration during setup:
- Euro valuta?
- No css output?
- Sample form?

### Other WordPress setup
- Import default content
- Options: Timezone?
- Options: Subtitle?
- Options: Permalink settings?
- Options: Statische pagina home als voorpagina instellen
- Options: Zoekmachines blokkeren
- Options: Reacties en avatars uitschakelen

## Configuration

```
my-site:
  repo: location_of_custom_provisioner
  hosts:
    - host_1 (primary)
    - host_2
    [...]
  custom:
    wp_version: [latest, nightly, version number]
    wp_type: [single, subdomain, subdirectory]
    site_title: site_title_of_wordpress
    db_name: super_secet_db_name

```

### Example: The minimum required configuration:

```
my-site:
  repo: https://github.com/erikjoling/custom-site-template.git
  hosts:
    - my-site.test
```

