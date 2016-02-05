tracker
=======

PARLO Progress Tracker

Installation for development

```bash
git clone https://github.com/21pstem/tracker
cd tracker
bundle install
printf "development:\n  adapter: sqlite3\n  database: db/devel.sqlite3\n  pool: 5\n  timeout: 5000\ntest:\n  adapter: sqlite3 \n  database: db/test.sqlite3\n  pool: 5\n  timeout: 5000" > config/database.yml
rake db:migrate && rake db:seed
```
