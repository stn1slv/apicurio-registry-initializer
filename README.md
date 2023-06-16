# Apicurio-registry-initializer
This is a repo of the initializer for demo cases which uploads JSON & XML Schemas to Apicurio Registry in OpenID Connect configuration with KeyCloak.

## How to run it?

### Preparing
Clone [docker-envs](https://github.com/stn1slv/docker-envs) repo:
```
git clone https://github.com/stn1slv/docker-envs.git
```
Go to root directory of the repo:
```
cd docker-envs
```
All the following docker-compose commands should be run from this directory.
### Running
You may want to remove any old containers to start clean:
```
docker rm -f schema-registry sr-init keycloak kc-init
```
Start up all components:
```
docker-compose -f compose.yml -f keycloak/compose.yml -f keycloak/initializer.yml -f apicurio-registry/compose-oidc.yml -f apicurio-registry/initializer.yml up
```
