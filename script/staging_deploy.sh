#!/bin/bash

git fetch --tags

echo "*************** BEGIN DEPLOYING TO STAGING (OLD UI)  *******************"
bundle exec cap staging deploy
echo "*************** BEGIN DEPLOYING TO STAGING (OLD UI)  *******************"

echo "*************** BEGIN DEPLOYING TO STAGING/PROUI (NEW UI)  *******************"
bundle exec cap stage_proui deploy
echo "*************** BEGIN DEPLOYING TO STAGING/PROUI (NEW UI)  *******************"
