#!/bin/bash

# Install gems
bundle install

# Install Cloud66 toolbelt
curl -sSL https://s3.amazonaws.com/downloads.cloud66.com/cx_installation/cx_install.sh | sudo bash