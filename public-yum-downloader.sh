#!/bin/bash
# 201612100000
# public-yum-downloader.sh
#
# public-yum-downloader script, to download a yum repository
# from public-yum.oracle.com
#
# Check updates on github
# https://github.com/kikitux/public-yum-downloader
#
# Author    :   Alvaro Miranda
# Email     :   kikitux@gmail.com
# Web       :   http://kikitux.net
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

cleanup() {
    exit 1
}

repo_create()
{
    cmds="rpm wget yum yumdownloader createrepo lsb_release"

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

        tmpdir="/var/tmp/public-yum-downloader"

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
            localrepofile=local-yum-el4.repo
            gpgkeyfile=RPM-GPG-KEY-oracle-el4
        elif [ $container_release_major = "5" ]; then
            repofile=public-yum-el5.repo
            localrepofile=local-yum-el5.repo
            gpgkeyfile=RPM-GPG-KEY-oracle-el5
        elif [ $container_release_major = "6" ]; then
            repofile=public-yum-ol6.repo
            localrepofile=local-yum-ol6.repo
            gpgkeyfile=RPM-GPG-KEY-oracle-ol6
        elif [ $container_release_major = "7" ]; then
            repofile=public-yum-ol7.repo
            localrepofile=local-yum-ol7.repo
            gpgkeyfile=RPM-GPG-KEY-oracle-ol7
        else
            die "Unsupported release $container_release_major"
        fi

        # to download from public-yum, we will modify this a bit
        wget -N -q $public_url/$repofile -O $tmpdir/$repofile    
        if [ $? -ne 0 ]; then
            die "Failed to download repo file $public_url/$repofile"
        fi
        
        # for lxc guests
        wget -N -q $public_url/$repofile -O $container_rootfs/$repofile    
        if [ $? -ne 0 ]; then
            die "Failed to download repo file $public_url/$repofile"
        fi
        wget -N -q $public_url/$gpgkeyfile -O $container_rootfs/$gpgkeyfile
        if [ $? -ne 0 ]; then
            die "Failed to download gpg-key file $public_url/$gpgkeyfile"
        fi

        if [ $manualrepo ]; then
            repo="$manualrepo"
        elif [ $container_release_minor = "UEKR3" ]; then
            if [ $container_release_major = "7"  ]; then
                repo="ol"$container_release_major"_"$container_release_minor"_latest"
            else
                repo="ol"$container_release_major"_"$container_release_minor"_latest"
            fi
        elif [ $container_release_minor = "UEK" ]; then
            if [ $container_release_major = "6" -o $container_release_major = "5"  ]; then
                repo="ol"$container_release_major"_"$container_release_minor"_latest"
            else
                die "Unsupported release $container_release_major.$container_release_minor"
            fi
        elif [ $container_release_minor = "latest" ]; then
            if [ $container_release_major = "4" -o $container_release_major = "5"  ]; then
                repo="el"$container_release_major"_"$container_release_minor
            else
                repo="ol"$container_release_major"_"$container_release_minor
            fi
        elif [ $container_release_major = "7" ]; then
                repo="ol"$container_release_major"_u"$container_release_minor"_base"
        elif [ $container_release_major = "6" ]; then
            if   [ $container_release_minor = "0" ]; then
                repo="ol"$container_release_major"_ga_base"
            else
                repo="ol"$container_release_major"_u"$container_release_minor"_base"
            fi
        elif [ $container_release_major = "5" ]; then
            if   [ $container_release_minor = "0" ]; then
                repo="el"$container_release_major"_ga_base"
            elif [ $container_release_minor -lt "6" ]; then
                repo="el"$container_release_major"_u"$container_release_minor"_base"
            else
                repo="ol"$container_release_major"_u"$container_release_minor"_base"
            fi
        elif [ $container_release_major = "4" -a $container_release_minor -gt "5" ]; then
            repo="el"$container_release_major"_u"$container_release_minor"_base"
        else
            die "Unsupported release $container_release_major.$container_release_minor"
        fi

        # replace url if they specified one
        if [ -n "$repourl" ]; then
            if [ -f $container_rootfs/$localrepofile ];then
                \mv $container_rootfs/$localrepofile $tmpdir/$localrepofile.old
            fi
            wget -N -q $public_url/$repofile -O $container_rootfs/$localrepofile

            #disable all repo
            sed -i "s|enabled=1|enabled=0|" $container_rootfs/$localrepofile

            #enable the previous repo that were enabled
            if [ -f $tmpdir/$localrepofile.old ];then
                enable_repo_list=$(tac $tmpdir/$localrepofile.old| sed -n "/enabled=1/,/\]/ s/\]//p" | tr -d '[]')
                for enable_repo in $enable_repo_list;do
                    echo "enabling previous repo $enable_repo on $repourl/$localrepofile"
                    sed -i "/\[$enable_repo\]/,/\[/ s/enabled=0/enabled=1/" $container_rootfs/$localrepofile
                done
                \rm $tmpdir/$localrepofile.old
            fi
            echo "set $repourl in $localrepofile"
            sed -i "s|baseurl=http://yum.oracle.com/repo|baseurl=$repourl/repo|" $container_rootfs/$localrepofile
            sed -i "s|gpgkey=http://yum.oracle.com|gpgkey=$repourl|" $container_rootfs/$localrepofile
            echo "file $container_rootfs/$localrepofile created"
            echo "use $repourl/$localrepofile for remote clients"
        else
            echo "No url specified for local repo"
        fi

        echo repo to download is $repo

        basepath=$(sed -n -e "s/\$basearch/$basearch/" -e "/\[$repo\]/,/\[/ s/baseurl=http.:\/\/yum.oracle.com//p" $tmpdir/$repofile)
        if [ ! "${basepath}" ]; then
          echo "basepath var empty, this happen once when oracle did rename public-yum to yum"
          echo "exitting since we can't grab the path"
          exit 1
        fi

        mkdir -p $container_rootfs/$basepath

        #set arch on public-yum repo file.
        sed -i "s/\$basearch/$basearch/" $tmpdir/$repofile
        
        #rename repo on public-yum file
        # reason 1: If the server have local repo file set, can cause troubles if are called the same
        # reason 2: Yumdownloader use local cache that get confused when host/repo are different arch
        #/var/tmp/yum-oracle-QUcCyV/x86_64/$releasever/ol6_u3_base_i386/repomd.xml
        #/var/tmp/yum-oracle-QUcCyV/x86_64/$releasever/ol6_u3_base_x86_64/repomd.xml
        repobasearch=$repo\_$basearch
        sed -i "s/\[$repo\]/\[$repobasearch\]/" $tmpdir/$repofile
        
        tmpinstallroot="$tmpdir/$repobasearch"
        #move repo file to chroot
        mkdir -p $tmpinstallroot/etc/yum.repos.d
        mv $tmpdir/$repofile $tmpinstallroot/etc/yum.repos.d
        
        if [ "$src" = "y" ];then
            basearch="$basearch,src --source"
            echo "Will include source rpm"
        fi
        
        echo generating list for $basearch
        yumdownloader_cmd="yumdownloader -v --url --disableplugin='*' --disablerepo='*' --enablerepo=$repobasearch --installroot=$tmpinstallroot --archlist=noarch,i386,i486,i586,i686,$basearch --destdir=$container_rootfs/$basepath"

        if [[ $repo =~ addons ]]; then
             echo "addons channel, no resolve for yumdownloader"
        else
             yumdownloader_cmd="$yumdownloader_cmd --resolve"
        fi
 
         #yumdownloader get some ERROR 416 and fail to download, so we will generate a list
         #and will use wget to handle the download
         downloadlist="$tmpdir/list"
 
        if [ "$min" = "y" ] && [[ $repo = *[0-9a]_base || $repo = *[0-9]_latest ]]; then
            echo "Will download the minimum packages for LXC host"
            pkgs="yum initscripts passwd rsyslog vim-minimal openssh-server dhclient chkconfig rootfiles policycoreutils oraclelinux-release"
            $yumdownloader_cmd $pkgs > $downloadlist.log
        else
            $yumdownloader_cmd '*' > $downloadlist.log
        fi
        
        if [ $? -ne 0 ]; then
            die "Failed to download, aborting."
        fi

    awk '/http:/' $downloadlist.log | sort -u > $downloadlist

    echo "wget will process $(wc -l < $downloadlist) files"

    #look and delete files of zero bytes
    find "$container_rootfs/$basepath" -size 0 -delete

    if [ $local ] ; then
        echo "verifying local path $local for rpms"
        while read line
            do  rpm=$(echo $line | rev | cut -d'/' -f1 | rev)
                find $local -name $rpm -exec cp -v -n {} "$container_rootfs/$basepath" \;
                if [ ! -f "$container_rootfs/$basepath/$rpm" ] ; then
                    echo "$rpm not found, downloading.."
                    echo wget -nc -P "$container_rootfs/$basepath" $line
                    wget -nc -P "$container_rootfs/$basepath" $line
                fi 
        done < $downloadlist
    else
        wget -nc -P "$container_rootfs/$basepath" -i $downloadlist
        if [ $? -ne 0 ]; then
            die "Failed to download, aborting."
        fi
    fi

    #run createrepo
    repodatacache="$container_rootfs/$basepath/repodata/.cache"
    mkdir -p "$repodatacache"
    echo "Downloading comps.xml"
    wget -N -q "$public_url/$basepath/repodata/comps.xml" -O "$container_rootfs/$basepath/repodata/comps.xml"
    if [ $? = 0 ] ; then
        echo "comps.xml downloaded"
    else
        echo "no comps.xml available"
    fi
    if [ -f "$container_rootfs/$basepath/repodata/comps.xml" ] ; then
       CREATEREPO="createrepo -g $container_rootfs/$basepath/repodata/comps.xml"
    else
       CREATEREPO="createrepo"
    fi
    if [ -f /etc/oracle-release -o -f /etc/redhat-release ] ; then
        host_release_version=`lsb_release --release |awk '{print $2}'`
        host_release_major=`echo $host_release_version |awk -F '.' '{print $1}'`
        host_release_minor=`echo $host_release_version |awk -F '.' '{print $2}'`
        if [ $host_release_major = 6 ] ; then
            $CREATEREPO --checksum sha --simple-md-filenames --cache "$repodatacache" "$container_rootfs/$basepath"
            if [ $? -ne 0 ]; then
                die "Please update to the latest createrepo and yum, yum-utils rpm"
            fi
        else
            $CREATEREPO --update --cache "$repodatacache" "$container_rootfs/$basepath"
        fi
    else
        echo "no oracle/redhat"
        host_release_major=5
        $CREATEREPO --update --cache "$repodatacache" "$container_rootfs/$basepath"
    fi
    echo "Downloading updateinfo.xml"
    wget -N -q "$public_url/$basepath/repodata/updateinfo.xml.gz" -O "$container_rootfs/$basepath/repodata/updateinfo.xml.gz"
    if [ $? = 0 ] ; then
        echo "updateinfo.xml downloaded"
        echo "updating repomd.xml with updateinfo.xml"
        gunzip -f "$container_rootfs/$basepath/repodata/updateinfo.xml.gz"
        if [ $host_release_major = 6 ] ; then
            modifyrepo --checksum sha --simple-md-filenames "$container_rootfs/$basepath/repodata/updateinfo.xml" "$container_rootfs/$basepath/repodata"
            if [ $? -ne 0 ] ; then
               die "please upgrade createrepo rpm"
            fi
        else
            modifyrepo "$container_rootfs/$basepath/repodata/updateinfo.xml" "$container_rootfs/$basepath/repodata"
        fi
    else
        echo "no updateinfo.xml available"
    fi
    if [ -n "$repourl" ]; then
        echo "enabling $repo on $localrepofile"
        sed -i "/\[$repo\]/,/\[/ s/enabled=0/enabled=1/" $container_rootfs/$localrepofile
    fi
    return 0
    ) 200>/var/tmp/public-yum-downloader/lock
}

usage()
{
cat <<EOF
-h|--help               this screen
-a|--arch=<arch>        architecture (ie. i386 or x86_64)
-R|--release=<release>  release to download
-P|--path=<path>        destination path of download (ie. /var/www/html)
-p|--proxy=<url>        proxy (ie http://proxy:3128)
-r|--repo=<repo>        manual repo download (ie. ol6_addons)
-m|--min                minimal package download for LXC host
-u|--url=<url>          local yum repo url (ie. http://mirandaa00)
-s|--src                download source rpm
-l|--local=<path>>      local path to check for rpms (ie. /media/iso)

Release is of the format "major.minor", for example "5.9", "6.4", or "6.latest"
To download latest UEK kernel, use 6.UEK or 5.UEK

EOF
    return 0
}

options=$(getopt -o ha:R:P:p:r:mu:sl: -l help,arch:,release:,path:,proxy:,repo:,min,url:,src,local: -- "$@")
if [ $? -ne 0 ]; then
    usage $(basename $0)
    exit 1
fi

eval set -- "$options"
while true
do
    case "$1" in
        -h|--help)      usage $0 && exit 0;;
        -a|--arch)      arch=$2; shift 2;;
        -R|--release)   container_release_version=$2; shift 2;;
        -P|--path)      container_rootfs=$2; shift 2;;
        -p|--proxy)     proxy=$2; shift 2;;
        -r|--repo)      manualrepo=$2; shift 2;;
        -m|--min)       min=y; shift 1 ;;
        -u|--url)       repourl=$2; shift 2;;
        -s|--src)       src=y; shift 1;;
        -l|--local)     local=$2; shift 1;;
        --)             shift 1; break ;;
        *)              break ;;
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
    else
        container_release_version="6.latest"
        echo "No release specified with -R, defaulting to 6.latest"
    fi
else
    echo "Release specified $container_release_version"
fi
container_release_major=`echo $container_release_version |awk -F '.' '{print $1}'`
container_release_minor=`echo $container_release_version |awk -F '.' '{print $2}'`

if [ -z "$container_rootfs" ]; then
    echo "No path specified with -P"
    echo "Specify the DocumentRoot of your webserver. ie -P /var/www/html"
    exit 1
fi

if [ "$proxy" ]; then
    echo "Using proxy $proxy"
    export http_proxy=$proxy https_proxy=$proxy proxy=$proxy
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

trap - EXIT
exit 0
