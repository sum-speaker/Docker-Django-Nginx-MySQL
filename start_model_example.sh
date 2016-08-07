#!/bin/bash

# Start mysql
/usr/bin/mysqld_safe &
sleep 10s

# Set password
MYSQL_ROOT_PASSWORD=`pwgen -c -n -1 12`
MYSQL_DJANGO_PASSWORD=`pwgen -c -n -1 12`
DJANGO_ADMIN_PASSWORD=`pwgen -c -n -1 12`

# Output password
echo -e "MYSQL_ROOT_PASSWORD = $MYSQL_ROOT_PASSWORD\nMYSQL_DJANGO_PASSWORD = $MYSQL_DJANGO_PASSWORD\nDJANGO_ADMIN_PASSWORD = $DJANGO_ADMIN_PASSWORD" > /home/django/password.txt

# Initialize MySQL
mysqladmin -u root password $MYSQL_ROOT_PASSWORD
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE django; GRANT ALL PRIVILEGES ON django.* TO 'django'@'localhost' IDENTIFIED BY '$MYSQL_DJANGO_PASSWORD'; FLUSH PRIVILEGES;"

pip3 install mysqlclient

# Modify Django settings.py
SETTING_PATH=`find /home/django/website -name settings.py`

# Add model_example app
sed -i "s|'django.contrib.staticfiles'|'django.contrib.staticfiles',\n    'model_example'|g" $SETTING_PATH

# Modify database setting to MySQL
sed -i "s|django.db.backends.sqlite3|django.db.backends.mysql|g" $SETTING_PATH
sed -i "s|os.path.join(BASE_DIR, 'db.sqlite3')|'django',\n        'USER': 'django',\n        'PASSWORD': '$MYSQL_DJANGO_PASSWORD'|g" $SETTING_PATH

# Modify static files setting
sed -i "s|STATIC_URL = '/static/'|STATIC_URL = '/static/'\n\nSTATIC_ROOT = os.path.join(BASE_DIR, 'static')|g" $SETTING_PATH

# Django setting
python3 /home/django/website/manage.py makemigrations
python3 /home/django/website/manage.py migrate
echo yes | python3 /home/django/website/manage.py collectstatic
echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@example.com', '$DJANGO_ADMIN_PASSWORD')" | python3 /home/django/website/manage.py shell

killall mysqld

# Start all the services
/usr/bin/supervisord -n