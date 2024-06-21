#!/bin/bash
# todo: sed in database for live domain with localhost
# todo: document and repo
# Create a docker-compose file to create a site from a repo
# Run this script from inside repo. It will create a docker-compose file from information it gathers.

#Display all the ports currently in use

echo "Run this script from the root of your repo. Put sql file in schema directory."

# Get the list of ports in use and save it to an array
ports_in_use=($(lsof -i -P -n | grep LISTEN | awk '{split($9,a,":"); print a[length(a)]}' | sort -n | uniq))

# Function to test if a port is in use
is_port_in_use() {
	local port=$1
	for used_port in "${ports_in_use[@]}"; do
		if [[ "$used_port" -eq "$port" ]]; then
			return 0 # port is in use
		fi
	done
	return 1 # port is not in use

}

echo "Enter repository"
read repository

echo "Enter database name:"
read database_name

echo "Ports in use: ${ports_in_use[@]}"

while true; do
	echo "Enter wordpress port (suggest between 80-100)"
	read wordpress_port

	if is_port_in_use "$wordpress_port"; then
		echo "Port $wordpress_port is in use. Please choose another port."
	else
		break
	fi
done

while true; do
	echo "Enter database port (suggest between 3306-3400)"
	read database_port

	if is_port_in_use "$database_port"; then
		echo "Port $database_port is in use. Please choose another port."
	else
		break
	fi
done

while true; do
	echo "Enter phpmyadmin port (suggest between 8080-8180)"
	read phpmyadmin_port

	if is_port_in_use "$phpmyadmin_port"; then
		echo "Port $phpmyadmin_port is in use. Please choose another port."
	else
		break
	fi
done

echo "Enter your wordpress database table prefix (i.e. wp_)"
read table_prefix

echo "Enter the live domain URL without https:// (e.g. example.com)"
read live_domain

echo "repository: $repository"
echo "database name: $database_name"
echo "ports: $wordpress_port, $phpmyadmin_port, $database_port"
echo "table prefix: $table_prefix"
echo "live domain: $live_domain"

git clone $repository .

# Check for valid directory
while true; do
	#prompt for plugins dir path
	echo "Please enter the path to the plugins directory"
	read dir_path

	# expand the ~ char to the home directory
	plugins_path=$(eval echo "$dir_path")

	# check if the entered path is valid
	if [ -d "$plugins_path" ]; then
		echo "Plugins directory found. Copying to ./wp-content..."

		# extract the directory name from the path
		dir_name=$(basename "$plugins_path")

		# Ensure ./wp-content exists
		mkdir -p ./wp-content

		# Copy plugins to wp-content
		cp -r "$plugins_path" "./wp-content/$dir_name"

		echo "Plugins directory has been copied to ./wp-content"
		break
	else
		echo "The specified path does not exist or is not a directory. Please check the path and try again."
	fi
done

# Check for valid schema directory
while true; do
	#prompt for schema dir path
	echo "Please enter the path to the SQL file"
	read file_path

	# expand the ~ char to the home directory
	expanded_file_path=$(eval echo "$file_path")

	# check if the entered path is valid
	if [ -f "$expanded_file_path" ] && [[ "$expanded_file_path" == *.sql ]]; then
		echo "SQL file found. Copying to schema..."

		#Ensure schema exists
		mkdir -p schema

		# Copy sql file to schema
		cp "$expanded_file_path" ./schema/

		sql_file="./schema/$(basename "$expanded_file_path")"
		local_site_url="http://localhost:$wordpress_port"

		# Replace live domain with local site url
		sed -i.bak "s|https://www.$live_domain|$local_site_url|g" "$sql_file"
		sed -i.bak "s|https://$lisve_domain|$local_site_url|g" "$sql_file"

		echo "URLs have been updated in the SQL file and the file has been copied to ./schema/"
		break
	else
		echo "The specified path does not exist or is not a .sql file. Please check the path and try again."
	fi

done

while true; do
	# Prompt for live domain name
	echo "Please enter the live domain name (e.g., example.com):"
	read live_domain

	# Validate the domain name format (simple regex check)
	if [[ "$live_domain" =~ ^[a-zA-Z0-9.-]+$ ]]; then
		echo "Creating .htaccess file in wp-content/uploads..."

		# Ensure wp-content/uploads directory exists
		mkdir -p wp-content/uploads

		# Create .htaccess file with the specified content
		cat <<EOL >wp-content/uploads/.htaccess
RewriteEngine on
RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule (.*) https://$live_domain/wp-content/uploads/\$1 [L]
EOL

		echo ".htaccess file has been created in wp-content/uploads."
		break
	else
		echo "Invalid domain name. Please enter a valid domain name."
	fi
done

# Create docker-compose file
cat <<EOL >docker-compose.yml
version: '3.9'

services:
  db:
    image: mysql:5.7
    platform: linux/amd64
    ports:
      - "$database_port:3306"
    volumes:
      - db_data:/var/lib/mysql
      - ./schema/:/docker-entrypoint-initdb.d 
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: $database_name
      MYSQL_PASSWORD: root

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    platform: linux/amd64
    ports:
      - "$wordpress_port:80"
    restart: always
    volumes:
      - ./wp-content:/var/www/html/wp-content
      - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: root
      WORDPRESS_DB_NAME: $database_name 
      WORDPRESS_TABLE_PREFIX: $table_prefix

  phpmyadmin:
    depends_on:
      - db
    image: phpmyadmin/phpmyadmin:latest
    platform: linux/amd64
    ports:
      - "$phpmyadmin_port:80"
    environment:
      PMA_HOST: db
      MYSQL_ROOT_PASSWORD: root

volumes:
  db_data: 


EOL

echo "docker-compose.yml created."
echo "running docker-compose up -d"

docker-compose up -d

url=http://localhost:$wordpress_port

echo "opening site at $url"

open "$url"
