#!/bin/bash
# =========================================
# Script: create-azure-sql-db.sh
# Purpose: Create Azure SQL Server and a single SQL Database
# Usage: ./create-azure-sql-db.sh <subscription_id> <client_id> <client_secret> <tenant_id> <resource_group> <location> <sql_server_name> <sql_admin_user> <sql_admin_pass> <db_name>
# Example: ./create-azure-sql-db.sh <sub_id> <client_id> <secret> <tenant> demo-rg eastasia demo-sql-server sqladmin MyP@ssw0rd demo-db
# =========================================

# ----------- Input Parameters -----------
SUBSCRIPTION_ID=$1
CLIENT_ID=$2
CLIENT_SECRET=$3
TENANT_ID=$4
RESOURCE_GROUP=${5:-demo-resource-group}
LOCATION=${6:-eastasia}
SQL_SERVER_NAME=${7:-demo-sql-server}
SQL_ADMIN_USER=${8:-sqladmin}
SQL_ADMIN_PASS=${9:-P@ssw0rd123!}  # Must meet Azure password complexity
DB_NAME=${10:-demo-db}

# ----------- Login using Service Principal -----------
echo "🔐 Logging in to Azure using Service Principal..."
az login --service-principal -u "$CLIENT_ID" -p "$CLIENT_SECRET" --tenant "$TENANT_ID" >/dev/null
az account set --subscription "$SUBSCRIPTION_ID"

# ----------- Create Resource Group if not exists -----------
if az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "✅ Resource Group $RESOURCE_GROUP already exists."
else
    echo "Creating Resource Group $RESOURCE_GROUP..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
fi

# ----------- Create SQL Server if not exists -----------
if az sql server show --name "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "✅ SQL Server $SQL_SERVER_NAME already exists."
else
    echo "Creating SQL Server $SQL_SERVER_NAME..."
    az sql server create \
        --name "$SQL_SERVER_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --admin-user "$SQL_ADMIN_USER" \
        --admin-password "$SQL_ADMIN_PASS"
fi

# ----------- Create SQL Database -----------
if az sql db show --name "$DB_NAME" --server "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "✅ SQL Database $DB_NAME already exists."
else
    echo "Creating SQL Database $DB_NAME..."
    az sql db create \
        --name "$DB_NAME" \
        --server "$SQL_SERVER_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --service-objective S0
fi

echo "🎉 Azure SQL Server and Database setup complete!"
