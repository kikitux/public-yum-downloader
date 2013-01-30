public-yum-downloader.sh
========================
20130131
Script to download a local copy of public-yum.oracle.com for a given repo.

public-yum-downloader.sh -h
-h|--help               this screen
-a|--arch=<arch>        architecture (ie. i386 or x86_64)
-R|--release=<release>  release to download for the new container
-P|--path=<path>)       destination path of download (ie. /var/www/html)
-p|--proxy=<url>)       proxy (ie http://proxy:3128)
-r|--repo=<repo>)       manual repo download (ie. the beta ol6_playground_latest)
-m|--min                minimal package download for LXC host
-u|--url=<url>          local yum repo url (ie. local yum mirror)
-s|--src                download source rpm
-2|--two                will generate separate local-yum-<4/5/6>-<arch> file

Release is of the format "major.minor", for example "5.8", "6.3", or "6.latest"



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



