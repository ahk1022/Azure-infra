#!/bin/bash
# =========================================
# Script: build-azure-environment-ci.sh
# Purpose: Create Azure Resource Group, App Service Plan, Web Apps, and Azure SQL Databases
# Usage: ./build-azure-environment-ci.sh <subscription_id> <client_id> <client_secret> <tenant_id> <resource_group> <location> <webapp1> <webapp2> <webapp3> <container_image> <sql_server_name> <sql_admin_user> <sql_admin_pass> <db1> <db2> <db3>
# Example: ./build-azure-environment-ci.sh <sub_id> <client_id> <secret> <tenant> demo-rg eastasia webapp1 webapp2 webapp3 nginx:latest my-sql-server sqladmin MyP@ssw0rd db1 db2 db3
# =========================================

# ----------- Input Parameters -----------
SUBSCRIPTION_ID=$1
CLIENT_ID=$2
CLIENT_SECRET=$3
TENANT_ID=$4
RESOURCE_GROUP=${5:-demo-resource-group}
LOCATION=${6:-eastasia}
WEBAPP1_NAME=${7:-demo-webapp-1}
WEBAPP2_NAME=${8:-demo-webapp-2}
WEBAPP3_NAME=${9:-demo-webapp-3}
CONTAINER_IMAGE=${10:-nginx:latest}

SQL_SERVER_NAME=${11:-demo-sql-server}
SQL_ADMIN_USER=${12:-sqladmin}
SQL_ADMIN_PASS=${13:-P@ssw0rd123!}  # Must meet Azure password complexity
DB1_NAME=${14:-demo-db1}
DB2_NAME=${15:-demo-db2}
DB3_NAME=${16:-demo-db3}

PLAN_NAME="${RESOURCE_GROUP}-plan"

# ----------- Login using Service Principal -----------
echo "🔐 Logging in to Azure using Service Principal..."
az login --service-principal -u "$CLIENT_ID" -p "$CLIENT_SECRET" --tenant "$TENANT_ID" >/dev/null
az account set --subscription "$SUBSCRIPTION_ID"

# ----------- Create Resource Group -----------
if az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "✅ Resource Group $RESOURCE_GROUP already exists."
else
    echo "Creating Resource Group $RESOURCE_GROUP..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
fi

# ----------- Create App Service Plan -----------
if az appservice plan show --name "$PLAN_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "✅ App Service Plan $PLAN_NAME already exists."
else
    echo "Creating App Service Plan $PLAN_NAME..."
    az appservice plan create \
        --name "$PLAN_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --is-linux \
        --sku B1 \
        --location "$LOCATION"
fi

# ----------- Create Web Apps -----------
for WEBAPP in "$WEBAPP1_NAME" "$WEBAPP2_NAME" "$WEBAPP3_NAME"; do
    if az webapp show --name "$WEBAPP" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
        echo "✅ Web App $WEBAPP already exists."
    else
        echo "Creating Web App $WEBAPP..."
        az webapp create \
            --resource-group "$RESOURCE_GROUP" \
            --plan "$PLAN_NAME" \
            --name "$WEBAPP" \
            --deployment-container-image-name "$CONTAINER_IMAGE"
    fi
done

# ----------- Create Azure SQL Server -----------
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

# ----------- Create SQL Databases -----------
for DB in "$DB1_NAME" "$DB2_NAME" "$DB3_NAME"; do
    if az sql db show --name "$DB" --server "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
        echo "✅ SQL Database $DB already exists."
    else
        echo "Creating SQL Database $DB..."
        az sql db create \
            --name "$DB" \
            --server "$SQL_SERVER_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --service-objective S0
    fi
done

echo "🎉 Azure environment setup complete!"
