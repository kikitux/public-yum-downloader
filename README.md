public-yum-downloader.sh
========================

Script to download a local copy of public-yum.oracle.com for a given repo.

It have been updated to include the updateinfo xml for Security errata, bug fixes, CVE, etc.

Updates:
==

The script now download updateinfo.xml from public-yum, that enable the local repo to have the errata/security information.


Short version:
==

examples:

if you want to 

download 6.latest (or keep updated) 

DocumentRoot for the webserver is /var/www/html

url will be http://mirandaa00

proxy is http://proxy:3128


public-yum-downloader.sh -P /var/www/html -p http://proxy:3128 -R 6.latest -a x86_64 --url http://mirandaa00


At the end of the run, will create a package /var/ww/html/local-yum-ol6.repo available as http://mirandaa00/local-yum-ol6.repo

if you want to 

only the minimal packages for an LXC container

version 6.4

DocumentRoot for the webserver is /var/www/html

proxy is http://proxy:3128


public-yum-downloader.sh -P /var/www/html -p http://proxy:3128 -R 6.4 -a x86_64


if you want to 

download latest UEK (or keep updated) 

DocumentRoot for the webserver is /var/www/html

url will be http://mirandaa00

proxy is http://proxy:3128


public-yum-downloader.sh -P /var/www/html -p http://proxy:3128 -R 6.UEK -a x86_64 --url http://mirandaa00





Long version:
==

This script will download a given repo from public-yum.oracle.com and create a local copy

The hierarchy is 100% the same as what is on public-yum

The script take 2 arguments, one is -P for the OS directory, and --url for where the same path will be public, so you can put the mirror in a different path

example, I have my own repo in /u02/stage/ and is shared like http://mirandaa00/stage

on my apache I have

    Alias /stage "/u02/stage/"

    <Directory "/u02/stage/">
    Options Indexes MultiViews FollowSymLinks
    AllowOverride None
    Order allow,deny
    Allow from all
    </Directory>

In that way, I have everything I want shared from my own local path

When you use the url, the script will create a local-yum-ol6.repo file with the url you gave, with GPG enabled, so you can be sure nothing wrong will happen in the middle

I use this script it this way

as root, i have /root/bin/dl.sh with this content

    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -R 6.latest --url http://mirandaa00/stage -l /u02/stage/repo/OracleLinux/OL6/
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -R 5.latest --url http://mirandaa00/stage -l /u02/stage/repo/OracleLinux/OL5/
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -R 4.latest --url http://mirandaa00/stage -l /u02/stage/repo/EnterpriseLinux/EL4/
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -R 6.4 --url http://mirandaa00/stage -l /u02/stage/repo/OracleLinux/OL6/
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -R 5.9 --url http://mirandaa00/stage -l /u02/stage/repo/OracleLinux/OL5/
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -R 4.9 --url http://mirandaa00/stage -l /u02/stage/repo/EnterpriseLinux/EL4/
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -R 4.8 --url http://mirandaa00/stage -l /u02/stage/repo/EnterpriseLinux/EL4/
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -R 6.UEK --url http://mirandaa00/stage
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -R 5.UEK --url http://mirandaa00/stage
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -r ol6_addons --url http://mirandaa00/stage
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -r el5_addons --url http://mirandaa00/stage
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -r el5_oracle_addons --url http://mirandaa00/stage
    ~/bin/public-yum-downloader.sh -P /u02/stage/ -p http://proxy:3128 -r ol6_playground_latest

the -l will look on that path to find the rpm, useful for example if you have a dvd and you want to use as initial cache

I do run my commands in that way as when 5.9 came out, I had a lot of those rpms in 5.8 or 5 latest, rite?

Worst thing that could happen, is the rpm is not there, and will have to download, but if it's there will copy it

for UEK and addons those are unique rpm, so I don't use -l

for the playground, that are the new kernel based on 3.x directly, i don't use --url, as I don't wat the script to enable that repo, but I do want to download what that channel have

so, for known versions 6.0 to 6.4 you can use -R 6.n or even -R 6.UEK

for other repos you can pass the name as -r repo
