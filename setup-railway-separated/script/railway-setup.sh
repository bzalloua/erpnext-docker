#!/bin/bash
set -e

require_var() {
    if [ -z "${!1}" ]; then
        echo "ERROR: $1 is not set" >&2
        exit 1
    fi
}

require_var RFP_DOMAIN_NAME
require_var RFP_SITE_ADMIN_PASSWORD
require_var FRAPPE_DB_PASSWORD

SITES_DIR="/home/frappe/frappe-bench/sites"

if [ -d "${SITES_DIR}/${RFP_DOMAIN_NAME}" ]; then
    echo "-> Site ${RFP_DOMAIN_NAME} already exists, skipping setup"
    exit 0
fi

echo "-> Create empty common site config"
su frappe -c "echo '{}' > '${SITES_DIR}/common_site_config.json'"

echo "-> Download Australian localisation app"
su frappe -c "cd /home/frappe/frappe-bench && bench get-app --branch=version-16 https://github.com/Arus-Info/ERPNext-Australian-Localisation.git || true"

echo "-> Ensure apps.txt contains Australian localisation"
grep -qxF "erpnext_australian_localisation" /home/frappe/frappe-bench/sites/apps.txt || \
echo "erpnext_australian_localisation" >> /home/frappe/frappe-bench/sites/apps.txt

echo "-> Create new site with ERPNext"
su frappe -c "bench new-site ${RFP_DOMAIN_NAME} \
    --admin-password ${RFP_SITE_ADMIN_PASSWORD} \
    --no-mariadb-socket \
    --db-root-password ${FRAPPE_DB_PASSWORD} \
    --install-app erpnext"

echo "-> Install Australian localisation"
su frappe -c "bench --site ${RFP_DOMAIN_NAME} install-app erpnext_australian_localisation"

su frappe -c "bench use ${RFP_DOMAIN_NAME}"

echo "-> Enable scheduler"
bench enable-scheduler
