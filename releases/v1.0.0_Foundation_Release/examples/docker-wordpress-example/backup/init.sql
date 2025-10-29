:~/examples/docker-wordpress-example/backup/init.sql
-- Initial database setup for WordPress
-- This file runs when the MySQL container is first started

CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED BY 'wordpress_password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;