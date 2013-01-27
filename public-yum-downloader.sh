#!/bin/bash
<<<<<<< HEAD
# 201301280120
=======
# 201301281015
>>>>>>> createrepo
# public-yum-downloader.sh
#
# public-yum-downloader script, to download a yum repository
# from public-yum.oracle.com
#
# Check updates on github
# https://github.com/kikitux/public-yum-downloader
#
# Author: Alvaro Miranda
# Email	: kikitux@gmail.com
# Web	: http://zerodowntime.blogspot.co.nz
# 
# Based on the lxc-oracle template script from Oracle
# from Wim Coekaerts and Dwight Engen
# Original lxc-oracle script: https://raw.github.com/lxc/lxc/staging/templates/lxc-oracle.in
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

die()
{
    echo "failed: $1"
    exit 1
}


repo_create()
{
    cmds="rpm wget yum yumdownloader createrepo"

    for cmd in $cmds; do
        which $cmd >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            die "The $cmd command is required, please install it"
        fi
    done

    mkdir -p /var/tmp/public-yum-downloader
    (
        flock -x 200
        if [ $? -ne 0 ]; then
            die "public-yum-downloader already running."
        fi

        echo "Downloading release $container_release_major for $basearch"

        # get yum repo file
		public_url=http://public-yum.oracle.com
        if [ -n "$repourl" ]; then
            yum_url=$repourl
        else
            yum_url=$public_url
        fi
        if   [ $container_release_major = "4" ]; then
            repofile=public-yum-el4.repo
            localrepofile=local-yum-el4-$basearch.repo
            gpgkeyfile=RPM-GPG-KEY-oracle-el4
        elif [ $container_release_major = "5" ]; then
            repofile=public-yum-el5.repo
            localrepofile=local-yum-el5-$basearch.repo
            gpgkeyfile=RPM-GPG-KEY-oracle-el5
        elif [ $container_release_major = "6" ]; then
            repofile=public-yum-ol6.repo
			localrepofile=local-yum-ol6-$basearch.repo
            gpgkeyfile=RPM-GPG-KEY-oracle-ol6
        else
            die "Unsupported release $container_release_major"
        fi
        wget -q $public_url/$repofile -O $container_rootfs/$repofile
        if [ ! -f $container_rootfs/$localrepofile ];then
			wget -q $public_url/$repofile -O $container_rootfs/$localrepofile
		fi
        if [ $? -ne 0 ]; then
            die "Failed to download repo file $public_url/$repofile"
        fi
        wget -q $public_url/$gpgkeyfile -O $container_rootfs/$gpgkeyfile
        if [ $? -ne 0 ]; then
            die "Failed to download gpg-key file $public_url/$gpgkeyfile"
        fi
        
		
        if [ $manualrepo ]; then
            repo="$manualrepo"
        elif [ $container_release_minor = "UEK" ]; then
            if [ $container_release_major = "6" -o $container_release_major = "5"  ]; then
                repo="ol"$container_release_major"_"$container_release_minor"_latest"
            else
                die "Unsupported release $container_release_major"
            fi
        elif [ $container_release_minor = "latest" ]; then
            if [ $container_release_major = "5" -o $container_release_major = "4"  ]; then
                repo="el"$container_release_major"_"$container_release_minor
            else
                repo="ol"$container_release_major"_"$container_release_minor
            fi
        elif [ $container_release_minor = "0" ]; then
            repo="ol"$container_release_major"_ga_base"
        elif [ $container_release_major = "5" ]; then
            if [ $container_release_minor -lt "5"  ]; then
                repo="el"$container_release_major"_u"$container_release_minor"_base"
            else
                repo="ol"$container_release_major"_u"$container_release_minor"_base"
            fi
        elif [ $container_release_major = "4" ]; then
            if [ $container_release_minor -lt "6"  ]; then
                die "Unsupported release $container_release_major"
            else
                repo="el"$container_release_major"_u"$container_release_minor"_base"
            fi
        else
            repo="ol"$container_release_major"_u"$container_release_minor"_base"
        fi
        
        echo Repo to download is $repo
		#Will enable the repo we are downloading
        sed -i "/\[$repo\]/,/\[/ s/enabled=0/enabled=1/" $container_rootfs/$localrepofile
        
                        # replace url if they specified one
        if [ -n "$repourl" ]; then
            sed -i "s|baseurl=http://public-yum.oracle.com/repo|baseurl=$repourl/repo|" $container_rootfs/$localrepofile
            sed -i "s|gpgkey=http://public-yum.oracle.com|gpgkey=$repourl|" $container_rootfs/$localrepofile
        fi
        

        # 
		basepath=$(sed -n -e "s/\$basearch/$basearch/" -e "/\[$repo\]/,/\[/ s/baseurl=http:\/\/public-yum.oracle.com//p" $container_rootfs/$repofile)
        mkdir -p $container_rootfs/$basepath
        
        if [ "$src" = "y" ];then
        	basearch="$basearch --source"
        	echo "Downloading source rpm"
        fi
        
		echo downlading $basearch
		yumdownloader_cmd="yumdownloader --disablerepo=* --enablerepo=$repo --resolve --installroot=/var/tmp --archlist=$basearch -c $container_rootfs/$repofile --destdir=$container_rootfs/$basepath"
 
        if [ "$min" = "y" ]; then
			echo "Will download the minimun packages for LXC host"
			pkgs="yum initscripts passwd rsyslog vim-minimal openssh-server dhclient chkconfig rootfiles policycoreutils oraclelinux-release"
			$yumdownloader_cmd $pkgs
		else
			$yumdownloader_cmd '*'
		fi
		
        if [ $? -ne 0 ]; then
            die "Failed to download and install the rootfs, aborting."
        fi
        
        #run createrepo
        repodatacache="$container_rootfs/$basepath/repodata/.cache"
		mkdir -p "$repodatacache"
		createrepo --update --cache "$repodatacache" "$container_rootfs/$basepath"

    ) 200>/var/tmp/public-yum-downloader/lock
}

usage()
{
cat <<EOF
-h|--help
-a|--arch=<arch>		architecture (ie. i386 or x86_64)
-R|--release=<release>	release to download for the new container
-P|--path=<path>)		destination path of download (ie. /var/www/html)
-p|--proxy=<url>)		proxy (ie http://proxy:3128)
-r|--repo=<repo>)		manual repo download (ie. ol6_playground)
-m|--min				minimal package download for LXC host
-u|--url=<url>			local yum repo url (ie. local yum mirror)
-s|--src				download source rpm
Release is of the format "major.minor", for example "5.8", "6.3", or "6.latest"
EOF
    return 0
}

options=$(getopt -o ha:R:P:p:r:mu:s -l help,arch:,release:,path:,proxy:,repo:,min,url:,src -- "$@")
if [ $? -ne 0 ]; then
    usage $(basename $0)
    exit 1
fi

eval set -- "$options"
while true
do
    case "$1" in
		-h|--help)		usage $0 && exit 0;;
		-a|--arch)		arch=$2; shift 2;;
		-R|--release)		container_release_version=$2; shift 2;;
		-P|--path)		container_rootfs=$2; shift 2;;
		-p|--proxy)		proxy=$2; shift 2;;
		-r|--repo)		manualrepo=$2; shift 2;;
		-m|--min)		min=y; shift 1 ;;
		-u|--url)		repourl=$2; shift 2;;
		-s|--src)		src=y; shift 1;;
		--)				shift 1; break ;;
		*)				break ;;
	esac
done

# make sure mandatory args are given and valid

if [ -z "$arch" ]; then
	arch=$(arch)
	echo "No arch specified with -a, defaulting to host arch $arch"
fi

basearch=$arch
if [ "$arch" = "i686" ]; then
    basearch="i386"
fi

if [ "$arch" != "i386" -a "$arch" != "x86_64" ]; then
    echo "Bad architecture, valid are i686 or x86_64"
    usage
    exit 1
fi

if [ -z "$container_release_version" ]; then
	if [[ $manualrepo == *l5* ]]; then
		container_release_version="5.latest"
	elif [[ $manualrepo == *l4* ]]; then
		container_release_version="4.latest"	
	else container_release_version="6.latest"
		echo "No release specified with -R, defaulting to 6.latest"
	fi
else
	echo "Release specified $container_release_version"
fi
container_release_major=`echo $container_release_version |awk -F '.' '{print $1}'`
container_release_minor=`echo $container_release_version |awk -F '.' '{print $2}'`

if which lsb_release >/dev/null 2>&1; then
    host_distribution=`lsb_release --id |awk '{print $3}'`
    host_release_version=`lsb_release --release |awk '{print $2}'`
    host_release_major=`echo $host_release_version |awk -F '.' '{print $1}'`
    host_release_minor=`echo $host_release_version |awk -F '.' '{print $2}'`
else
    if   [ -f /etc/fedora-release ]; then
       host_distribution="Fedora"
       host_release_version=`cat /etc/fedora-release |awk '{print $3}'`
       host_release_major=$host_release_version
       host_release_minor=0
    elif [ -f /etc/oracle-release ]; then
       host_distribution="OracleServer"
       host_release_version=`cat /etc/oracle-release |awk '{print $5}'`
       host_release_major=`echo $host_release_version |awk -F '.' '{print $1}'`
       host_release_minor=`echo $host_release_version |awk -F '.' '{print $2}'`
    else
       echo "Unable to determine host distribution, ensure lsb_release is installed"
       exit 1
    fi
fi
echo "Host is $host_distribution $host_release_version"

if [ -z "$container_rootfs" ]; then
	echo "No path specified with -P"
	echo "Specify the DocumentRoot of your webserver. ie -P /var/www/html"
	exit 1
fi

if [ "$proxy" ]; then
	echo "Using proxy $proxy"
	export http_proxy=$proxy https_proxy=$proxy
else
	echo "No proxy specified"
fi

touch $container_rootfs/.test 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Error: No write permissions on $container_rootfs for $USER"
    exit 1
fi

trap cleanup SIGHUP SIGINT SIGTERM

repo_create
