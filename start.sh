#!/bin/bash

# Check parameter value and set defaults
if [ -z "$KEYCLOAK_USER" ]; then
    export KEYCLOAK_USER=admin
fi
if [ -z "$KEYCLOAK_PASSWORD" ]; then
    export KEYCLOAK_PASSWORD=admin
fi
if [ -z "$KEYCLOAK_ENDPOINT" ]; then
    export KEYCLOAK_ENDPOINT=http://host.docker.internal:8080/auth
fi
if [ -z "$KEYCLOAK_REALM" ]; then
    export KEYCLOAK_REALM=master
fi
if [ -z "$KEYCLOAK_CLIENT_ID" ]; then
    export KEYCLOAK_CLIENT_ID=registry-api
fi
if [ -z "$KEYCLOAK_CLIENT_SECRET" ]; then
    export KEYCLOAK_CLIENT_SECRET=registry-api-secret
fi
if [ -z "$APICURIO_ENDPOINT" ]; then
    export APICURIO_ENDPOINT=http://host.docker.internal:8180
fi

# Wait for KeyCloak
until [ "$(curl -sL -w "%{http_code}\\n" $KEYCLOAK_ENDPOINT/realms/$KEYCLOAK_REALM/.well-known/openid-configuration -o /dev/null)" == "200" ]
do
    echo "$(date) - still trying to connect to KeyCloak at $KEYCLOAK_ENDPOINT"
    sleep 5
done

# Wait for Apicurio Registry
until [ "$(curl -sL -w "%{http_code}\\n" $APICURIO_ENDPOINT -o /dev/null)" == "200" ]
do
    echo "$(date) - still trying to connect to Apicurio Registry at $APICURIO_ENDPOINT"
    sleep 5
done

# Get JWT token
echo "Getting JWT for $KEYCLOAK_USER user";
export TOKEN=$(curl -ss -d "username=$KEYCLOAK_USER&password=$KEYCLOAK_PASSWORD&grant_type=password&client_id=$KEYCLOAK_CLIENT_ID&client_secret=$KEYCLOAK_CLIENT_SECRET" -H "Content-Type: application/x-www-form-urlencoded" -X POST $KEYCLOAK_ENDPOINT/realms/$KEYCLOAK_REALM/protocol/openid-connect/token | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

# Create JSON Schema
var=$(curl -d @purchaseOrder.json -H 'X-Registry-ArtifactType: JSON'  -H 'X-Registry-Name: PurchaseOrder'  -H 'X-Registry-ArtifactId: PurchaseOrderJSON'  -H 'X-Registry-Version: 3.1.6'  -H 'X-Registry-Description: Artifact description' -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN"  -sL -w "%{http_code}\n" -X POST $APICURIO_ENDPOINT/apis/registry/v2/groups/sales/artifacts -o /dev/null)
if [ "$var" == "200" ]; then
    echo "JSON Schema created";
else
    if [ "${var: -3}" == "409" ]; then
        echo "JSON Schema exists";
    else
        echo "An error occurred during JSON Schema creation: $var";
    fi
fi

# Create XML Schema
var=$(curl -d @purchaseOrder.xsd -H 'X-Registry-ArtifactType: XSD' -H 'X-Registry-ArtifactId: PurchaseOrderXSD' -H 'X-Registry-Name: PurchaseOrder' -H 'X-Registry-Version: 3.1.6' -H 'X-Registry-Description: XSD Artifact description' -H 'Accept: application/json'  -H "Content-Type: application/xml" -H "Authorization: Bearer $TOKEN"  -sL -w "%{http_code}\n" -X POST $APICURIO_ENDPOINT/apis/registry/v2/groups/sales/artifacts -o /dev/null)
if [ "$var" == "200" ]; then
    echo "XML Schema created";
else
    if [ "${var: -3}" == "409" ]; then
        echo "XML Schema exists";
    else
        echo "An error occurred during XML Schema creation: $var";
    fi
fi