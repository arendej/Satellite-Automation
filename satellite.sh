#!/bin/bash

# Usage - ./satellite.sh <redhat_portal_username> <redhat_portal_password>

EMAIL=$1
PASSWORD=$2

SATELLITE_DEFAULT_ORG="Lab"
SATELLITE_DEFAULT_LOCATION="Toronto"

SATELLITE_USERNAME="stadmin"
SATELLITE_PASSWORD="redhat"

# Register server to Red Hat
echo ""
echo "*------------------------------------------------*"
echo "*----- Registering server to Red Hat Portal -----*"
echo "*------------------------------------------------*"
subscription-manager register --username $EMAIL --password $PASSWORD
POOL_ID="$(subscription-manager list --available --matches "Red Hat Satellite" \
                | grep "Pool ID:" | cut -d ':' -f 2 | awk 'FNR == 1 {print}')"

# Attach Satellite subscription to server
echo ""
echo "*------------------------------------------------*"
echo "*-- Attaching Satellite subscription to server --*"
echo "*------------------------------------------------*"
subscription-manager attach --pool $POOL_ID

# Disable all repositories
echo ""
echo "*------------------------------------------------*"
echo "*---------- Disabling all repositories ----------*"
echo "*------------------------------------------------*"
subscription-manager repos --disable "*"

# Enable repositories needed for Satellite
echo ""
echo "*------------------------------------------------*"
echo "*-- Enabling repositories needed for Satellite --*"
echo "*------------------------------------------------*"
subscription-manager repos --enable rhel-7-server-rpms \
                           --enable rhel-server-rhscl-7-rpms \
                           --enable rhel-7-server-satellite-6.2-rpms

# Installing Satellite packages
echo ""
echo "*------------------------------------------------*"
echo "*--------- Installing Satellite Packages --------*"
echo "*------------------------------------------------*"
yum clean all
yum install satellite -y

# Customizing Satellite answers file
echo ""
echo "*------------------------------------------------*"
echo "*------ Customizing Satellite Answers File ------*"
echo "*------------------------------------------------*"
python generate-answers-file.py $SATELLITE_DEFAULT_ORG $SATELLITE_DEFAULT_LOCATION
cp /etc/foreman-installer/scenarios.d/satellite-answers.yaml \
   /etc/foreman-installer/scenarios.d/satellite-answers.yaml.old
mv satellite-answers.yaml /etc/foreman-installer/scenarios.d/

# Install Satellite
echo ""
echo "*------------------------------------------------*"
echo "*------------- Installing Satellite -------------*"
echo "*------------------------------------------------*"
satellite-installer --scenario satellite -v \
                    --foreman-admin-username $SATELLITE_USERNAME \
                    --foreman-admin-password $SATELLITE_PASSWORD

# Update Firewall
echo ""
echo "*------------------------------------------------*"
echo "*-------------- Updating Firewall ---------------*"
echo "*------------------------------------------------*"
firewall-cmd --zone=public --add-service=RH-Satellite-6 --permanent
firewall-cmd --zone=public --add-service=RH-Satellite-6
