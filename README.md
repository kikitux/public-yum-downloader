public-yum-downloader.sh
========================
20130131
Script to download a local copy of public-yum.oracle.com for a given repo.

examples:

if you want to 
download 6.latest (or keep updated) 
DocumentRoot for the webserver is /var/www/html
url will be http://mirandaa00
proxy is http://proxy:3128

public-yum-downloader.sh -P /var/www/html -p http://proxy:3128 -R 6.latest -a x86_64 --url http://mirandaa00

At the end of the run, will create a package /var/ww/html/local-yum-ol6.repo available as http://mirandaa00/local-yum-ol6.repo


if you want to 
download latest UEK (or keep updated) 
DocumentRoot for the webserver is /var/www/html
url will be http://mirandaa00
proxy is http://proxy:3128

public-yum-downloader.sh -P /var/www/html -p http://proxy:3128 -R 6.UEK -a x86_64 --url http://mirandaa00



