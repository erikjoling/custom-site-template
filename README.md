# VVV Custom site template
For when you just need a new WordPress site

- Version: 1.0-beta-2
- Author: Erik Joling <erik@joling.me>

## Overview
This template will allow you to create a WordPress dev environment using only `vvv-custom.yml`.

This is a custom fork of the official VVV custom site template. [See their repo for more documentation](https://github.com/Varying-Vagrant-Vagrants/custom-site-template).

## Todo
- Maybe create and install new custom theme (based on EJO Starter Theme)?

# Configuration

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
    gf_license: gravityforms_licence_key (custom setting)

```

### Example: The minimum required configuration:

```
my-site:
  repo: https://github.com/erikjoling/custom-site-template.git
  hosts:
    - my-site.test
```