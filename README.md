# docker-start-script
Create and start a local wp installation in docker

## TLDR: start the script and follow the prompts
### or
## Preparation
Put dc_create.sh somewhere on your computer.
* Create the directory you want to run your container from. I run mine from 
```bash
~/dev/container-name
```
* Change to that directory in terminal.
* Export the database from the live site you are copying and note its location.
* You will need:
** the name of the live domain (i.e., example.com)
** the link to the repository
** the name of the database 
** a saved export of the database
** a plugins directory saved locally that has at least ACF in it 

* You will be prompted to enter the repository. It will be installed where you are. The script will initialize the repository locally.
* You will be asked to enter the database name (as in examplecom)
* The script will list the ports that are being used and prompt you to enter (open) ports for wordpress, database and phpmyadmin.
* You will be asked to enter the path to the plugins directory (i.e. ~/Downloads/plugins). The script will put that directory inside wp-content.
* The script will ask you for the path to the sql file (i.e. ~/Downloads/examplecom.sql). The script will replace the site url and home url in []_options with the local url.
* The script will create an .htaccess file in wp-content/uploads to link to the images on the live site.
* The script will create a docker-compose.yml file in the directory you are in. From there you can run

```bash
docker-compose up -d
```
and your site will be ready to view at the url provided at the end of the script.


