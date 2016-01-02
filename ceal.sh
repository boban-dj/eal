#!/bin/bash
#Effective & Easy (Ewancoder) Arch Linux (EAL) install script - useful tool for reinstalling your arch linux and setting up all the programs automatically
#Copyright (c) 2014-2015 Ewancoder (Ewan Zyryanov) <ewancoder@gmail.com>
version="2.4 Interactive, 2015"
release="2.4.0 Interactive"

#Common settings
    hostinstall=0 #Install from within already running distro
    iso=http://ftp.byfly.by/pub/archlinux/iso/`date +%Y.%m.01`/arch/x86_64/airootfs.sfs #Path to Arch linux ROOT (fs.sfs) image, need for $hostinstall=1

    auto=0 #Install automatically, pause only when error occurs. If $auto=0, the script will pause at the each step and let you continue by pressing [RETURN]
    verbose=1 #Show each executed command and values of used variables
    substitute=1 #Give detailed command line with all variables already substituted, if it is 0 - show "command $with $variables"
    timeout=0  #When error occurred, wait N seconds and try again. Set this to 0 if you don't want script to repeat automatically: it will wait for your input

    hostname=arch_ewan #Hostname of the PC
    timezone=Europe/Amsterdam #Your timezone in /usr/share/zoneinfo
    locale=( en_US.UTF-8 ) #Locales which you need. System locale will be the first
    mirror=( Netherlands United States) #List of repository countries in the order of importance
    #font=cyr-sun16 #Console font [I don't need it]

#Internet configuration
    network=2 #1 - netctl, 2 - dhcpcd, 0 - do NOT setup
    profile=ethernet-static #netctl profile in /etc/netctl/examples
    interface=enp2s0 #Network interface [see ip link]
    ip=192.168.100.21 #Static IP address
    dns=192.168.100.1 #DNS to use (usually, your router address)
    essid=TTT #Name of access point for wireless connection
    key=192837465 #Key for wireless connection

#Devices: place them in the order of mounting ('/' goes before '/home'), no slash in the end ('/home', not '/home/')
    description=( Root ) #Just text info which will display during install
    device=( /dev/archlinux/root ) #Devices which is to mount to corresponding mount points
    mount=( / ) #Mount points starting from '/'
    type=( ext4 ) #Filesystem
    option=( rw,relatime ) #Options (discard works only for SSD)
    dump=( 0  ) #Make backup if 1 provided (usually 0)
    pass=( 1 ) #Used by fsck to check partitions in order (usually root = 1, other = 2)

#Additional devices
    mbr=/dev/sda #Grub MBR device (where to install bootloader)
    #windows=/dev/sdb1 #Copy fonts from windows system partition (C:\Windows\Fonts)
    #temp=/dev/sda10 #If you are installing from host-system ($hostinstall=1) and you have less than 1G free on '/', you will need additional partition to extract ROOT filesystem image

#Users
    user=boban #User login. Could be more than 1 like this: user=( ewancoder seconduser )
    shell=/bin/bash #Default shell
    #Each 'groups' entry is for separate user, the groups itself divided by comma (','). Group 'user' added to all users automatically (there's no need to include it here)
    group=fuse,uucp,wheel #Add user in these groups, separate by comma (,)
    main=${user[0]} #Main user of the system: used later as reference. I am setting it as 'ewancoder'
    sudoers="$main ALL=(ALL) NOPASSWD: /usr/bin/pacman" #Sudoers additional entries
    userscript=( ewancoder_script.sh ) #Script to execute as user after install

#Git configuration
    gitname=$main #Git user name
    gitemail=$main@gmail.com #Git email
    gittool=vimdiff #Tool to use as diff
    giteditor="nano" #Default editor

    gitrepo=( $main/dotfiles $main/etc ) #All these repos will be cloned from github to corresponding folders
    gitfolder=( /home/$main/.dotfiles /etc/.dotfiles ) #Set corresponding folders without '/' at the end
    gitrule=( $main:users '' ) #CHOWN rule for whole folder content ('root' as default)
    gitbranch=( '' '' ) #Branch to checkout
    gitmodule=( "" ) #Sumbodules to pull (remove if you don't need any)
    gitlink=( /home/$main /etc ) #Where to link ALL content from the repo [DOTFILES automation]

#Execute commands after install
    #Restore backup [FROM] [TO]
    backup=(
        "/mnt/backup/Arch/ /home/$main/"
    )
    rootscript=root_script.sh #Script executed after install

#Software configuration
    #Titles shows during install
    softtitle=(
        Drivers
        Audio
        Core
        Styling
        Web
        Office
        Coding
        Tools
    )
    #Essential AUR software, installed before system boot
    buildbefore=( canto-next-git compton cv dmenu2 dunst-git gtk-theme-espresso gcalcli gxkb slimlock-git slim-archlinux-solarized-spiral wmii-hg )
    #Long-builded AUR software, installed after system boot
    buildafter=( canto-curses-git chromium-pepper-flash hyphen-ru hunspell-ru jmtpfs latex-beamer latex-pscyr pencil popcorntime-bin python-pygame-hg syncplay pasystray-git )
    term="urxvt -e" #Terminal to install $buildafter software within
    #Packages (set drivers first for no-conflict)
    software=(
        "lib32-nvidia-libgl mesa nvidia nvidia-libgl phonon-qt5-gstreamer ttf-dejavu"
        "alsa-plugins alsa-utils lib32-alsa-plugins lib32-libpulse pulseaudio pulseaudio-alsa"
        "cronie devilspie udevil feh fuse git gksu keychain libnotify mplayer openssh p7zip pygtk redshift rsync rxvt-unicode screen sshfs tig tilda transset-df unrar unclutter unzip urxvt-perls wpa_supplicant xclip xdotool xorg-server xorg-server-utils xorg-xinit zsh"
        "faience-icon-theme ffmpegthumbnailer terminus-font tumbler"
        "chromium deluge jre8-openjdk icedtea-web net-tools skype"
        "anki calligra-krita filelight geeqie gource gvim impressive kdegraphics-okular libreoffice-fresh hyphen hyphen-en hunspell hunspell-en mc scrot thunar vlc"
        "ctags mono pygmentize python python-matplotlib python-numpy python-pyserial python-requests python-scipy python-sphinx python2-pygments texlive-core texlive-humanities texlive-langcyrillic texlive-latexextra texlive-pictures texlive-science wine"
        "dosfstools encfs gparted ntfs-3g smartmontools thefuck virtualbox"
    )
    #Services to enable
    service=(
        cronie
        systemd-networkd
        systemd-timesyncd
        deluged
    )

#===== INTERFACE =====
#Color constants
    Green=`tput setaf 2`
    Yellow=`tput setaf 3`
    Red=`tput setaf 1`
    Blue=`tput setaf 6`
    Bold=`tput bold`
    Def=`tput sgr0`

#Message function - neat output
mess(){
    if [ -f /var/lib/pacman/db.lck ]; then
        sudo rm -f /var/lib/pacman/db.lck #Need this in case pacman is still locked from last operation when installing on ssd very quicklky
    fi

    #Determine 'option' and 'message'
    if [ "${#1}" -gt "2" ]; then
        o=$2
        m=$1
    else
        o=$1
        m=$2
    fi

    #Stylize message
    case $o in
        "-p")
            Style="$Bold$Yellow\n-> $m [MANUAL]$Def"
            step=$m
            ;;
        "-w")
            Style="\n$Bold$Red! $m$Def"
            ;;
        "-t")
            Line="$(printf "%$(tput cols)s\n"|tr ' ' '-')"
            Style="\n$Line$Bold$Green\n-> $m$Def\n$Line"
            step=$m
            ;;
        "-q")
            Style="$Bold$Red$m$Def"
            ;;
        "-v")
            Style="$Blue-> $m$Def"
            echo $m | grep -oP '(?<!\[)\$[{(]?[^"\s\/\047.\\]+[})]?' | uniq > vars
            if [ ! "`cat vars`" == "" ]; then
                while read -r p; do
                    value=`eval echo $p`
                    Style=`echo -e "$Style\n\t$Green$p = $value$Def"`
                done < vars
            fi
            rm vars
            ;;
        *)
            Style="$Bold$Green\n-> $Def$Bold$m$Def"
            step=$m
            ;;
    esac

    #Print message
    if [ "$o" == "-v" ]; then
        echo -en "$Style\n"
    elif [ "$o" == "-p" ]; then
        echo -en "$Style"
        read
    else
        echo -e "$Style"
        if [ "$o" == "-w" -o "$o" == "-p" ] || [ "$o" == "" -a $auto -eq 0 ]; then
            read -p $Bold$Yellow"Continue [ENTER]"$Def
        fi
    fi
}
