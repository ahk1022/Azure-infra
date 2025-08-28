#!/bin/bash
set -euo pipefail

# ============
# Input Variables (replace or pass as env vars before running)
# ============
RESOURCE_GROUP="${RESOURCE_GROUP:-demo-resource-group}"
LOCATION="${LOCATION:-eastasia}"
PLAN_NAME="${PLAN_NAME:-$RESOURCE_GROUP-plan}"
WEBAPP1_NAME="${WEBAPP1_NAME:-demo-webapp-1}"
WEBAPP2_NAME="${WEBAPP2_NAME:-demo-webapp-2}"
WEBAPP3_NAME="${WEBAPP3_NAME:-demo-webapp-3}"
CONTAINER_IMAGE="${CONTAINER_IMAGE:-nginx:latest}"
SQL_SERVER_NAME="${SQL_SERVER_NAME:-demo-sql-server}"
SQL_ADMIN_USER="${SQL_ADMIN_USER:-sqladmin}"
SQL_ADMIN_PASS="${SQL_ADMIN_PASS:-YourP@ssword123!}"
DB_NAME="${DB_NAME:-demo-db}"

echo "🚀 Starting Azure environment setup..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "App Service Plan: $PLAN_NAME"
echo "Web Apps: $WEBAPP1_NAME, $WEBAPP2_NAME, $WEBAPP3_NAME"
echo "SQL Server: $SQL_SERVER_NAME"
echo "Database: $DB_NAME"

# ============
# Resource Group
# ============
if az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
  echo "✅ Resource Group $RESOURCE_GROUP exists"
else
  az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
fi

# ============
# App Service Plan
# ============
if az appservice plan show --name "$PLAN_NAME" --resource-group "$RESOURCE_GROUP" > /dev/null 2>&1; then
  echo "✅ App Service Plan $PLAN_NAME exists"
else
  az appservice plan create \
    --name "$PLAN_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --is-linux \
    --sku B1 \
    --location "$LOCATION"
fi

# ============
# Web Apps
# ============
for WEBAPP in "$WEBAPP1_NAME" "$WEBAPP2_NAME" "$WEBAPP3_NAME"; do
  if az webapp show --name "$WEBAPP" --resource-group "$RESOURCE_GROUP" > /dev/null 2>&1; then
    echo "✅ Web App $WEBAPP exists"
  else
    az webapp create \
      --resource-group "$RESOURCE_GROUP" \
      --plan "$PLAN_NAME" \
      --name "$WEBAPP" \
      --deployment-container-image-name "$CONTAINER_IMAGE"
  fi
done

# ============
# Ensure Microsoft.Sql registered
# ============
REG_STATE=$(az provider show --namespace Microsoft.Sql --query "registrationState" -o tsv || echo "NotRegistered")
if [ "$REG_STATE" != "Registered" ]; then
  echo "⚠ Microsoft.Sql is not registered. Registering now..."
  az provider register --namespace Microsoft.Sql
  for i in {1..30}; do
    REG_STATE=$(az provider show --namespace Microsoft.Sql --query "registrationState" -o tsv || echo "NotRegistered")
    if [ "$REG_STATE" == "Registered" ]; then
      echo "✅ Microsoft.Sql registration completed."
      break
    fi
    echo "⏳ Waiting for registration..."
    sleep 10
  done
else
  echo "✅ Microsoft.Sql is already registered."
fi

# ============
# SQL Server
# ============
if az sql server show --name "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP" > /dev/null 2>&1; then
  echo "✅ SQL Server $SQL_SERVER_NAME exists"
else
  az sql server create \
    --name "$SQL_SERVER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --admin-user "$SQL_ADMIN_USER" \
    --admin-password "$SQL_ADMIN_PASS"
fi

# ============
# SQL Database
# ============
if az sql db show --name "$DB_NAME" --server "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP" > /dev/null 2>&1; then
  echo "✅ SQL Database $DB_NAME exists"
else
  az sql db create \
    --name "$DB_NAME" \
    --server "$SQL_SERVER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --service-objective S0 \
    --backup-storage-redundancy Local
fi

echo "🎉 Azure environment setup completed successfully."
