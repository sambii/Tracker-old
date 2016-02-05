#!/bin/bash

set -e

git fetch --tags

echo "*************** BEGIN DEPLOYING TO PRODUCTION EGYPT  *******************"
bundle exec cap production_egypt deploy
echo "*************** FINISH DEPLOYING TO PRODUCTION EGYPT *******************"

printf "*\n*\n*\n*\n*\n*\n*\n*\n*\n*\n"

echo "*************** BEGIN DEPLOYING TO PRODUCTION USA  *******************"
bundle exec cap production_usa deploy
echo "*************** FINISH DEPLOYING TO PRODUCTION USA *******************"

printf "*\n*\n*\n*\n*\n*\n*\n*\n*\n*\n"

echo "*************** BEGIN DEPLOYING TO PRODUCTION MC2  *******************"
bundle exec cap production_mc2 deploy
echo "*************** FINISH DEPLOYING TO PRODUCTION MC2 *******************"