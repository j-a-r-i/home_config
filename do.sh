#!/bin/bash

VERSION=4.14.97
KVERSION=48
export GTK2_RC_FILES=/usr/share/themes/Xamarin-Dark/gtk-2.0/gtkrc

SRC_DIR=/mnt/src

#-------------------------------------------------------------------------------
function cleanup_system {
    rm /usr/share/doc/*/changelog.gz
    rm /usr/share/doc/*/changelog.Debian.gz
    rm /usr/share/doc/*/copyright
    rm -R /usr/share/locale/{a?,b?,c?,d?,f?,g?,h?,i?,j?,k?,l?}
    rm -R /usr/share/man/??
}

#-------------------------------------------------------------------------------
case $1 in
    dk) # download kernel
	echo "download kernel..." 
	cd ${SRC_DIR}
	wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${VERSION}.tar.xz
	tar xf linux-${VERSION}.tar.xz
	rm linux-${VERSION}.tar.xz
	cp /boot/config-$(uname -r) linux-${VERSION}
	cd linux-${VERSION}
	make oldconfig
	;;
    ik) # install kernel
	echo "install kernel..."
	cd ${SRC_DIR}
	sudo dpkg -i linux-headers-${VERSION}.j${KVERSION}_${KVERSION}_amd64.deb linux-image-${VERSION}.j${KVERSION}_${KVERSION}_amd64.deb linux-libc-dev_${KVERSION}_amd64.deb
	;;
    bx) # build x86 kernel
	echo "build x86 kernel ${VERSION}-${KVERSION}"
	cd ${SRC_DIR}/linux-${VERSION}

	make nconfig
	cp .config ${HOME}/config_${KVERSION}

	#make-kpkg clean
	#fakeroot make-kpkg -j3 --initrd --append-to-version=-j${VERSION} --revision=${VERSION} kernel_image kernel_headers

	make clean
	make -j4 KDEB_PKGVERSION=${KVERSION} LOCALVERSION=.j${KVERSION} bindeb-pkg
	;;
    br) # build raspberry pi kernel
	echo "build RPI kernel"
	cd ${SRC_DIR}/linux-${VERSION}

	#make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- multi_v7_defconfig

	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- nconfig
	cp .config /home/jari/rpi_${KVERSION}
    
	make -j3 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
	;;
    be) # build emacs
	cd ${SRC_DIR}/emacs-26.1
	./configure --prefix=/opt -q \
		    --enable-silent-rules \
		    --without-selinux \
		    --with-sound=no \
		    --with-x-toolkit=gtk2 \
		    --with-xpm=no \
		    --with-gif=no \
		    --with-tiff=no \
		    --with-gnutls=no \
		    --disable-acl
	make
	;;
    bt) # build tvheadend
	cd ${SRC_DIR}/tvheadend-4.2.1
	./configure --prefix=/opt \
		    --disable-satip_server \
		    --disable-satip_client \
		    --disable-hdhomerun_static \
		    --disable-iptv \
		    --disable-avahi \
		    --disable-ffmpeg_static \
		    --disable-libx264 \
		    --disable-libx264_static \
		    --disable-libx265 \
		    --disable-libx265_static \
		    --disable-libvpx \
		    --disable-libvpx_static \
		    --disable-libtheora \
		    --disable-libtheora_static \
		    --disable-libvorbis \
		    --disable-libvorbis_static \
		    --disable-libfdkaac \
		    --disable-libfdkaac_static \
		    --disable-nvenc  \
		    --disable-libav
	make
	;;
    dl) # debian package list by size
	echo "dpkg list"
	dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n
	;;
    du) # debian upgrade
	sudo apt update
	sudo apt upgrade
	;;
    ds) # debian setup
        apt install emacs25 xterm wmaker xserver-xorg xinit \
	    open-vm-tools-dkms open-vm-tools-desktop \
	    deborphan ncdu htop libncurses5-dev dialog \
	    x11-xserver-utils sudo tmux picocom \
	    --no-install-recommends
        ;; 
    vn) # start vnc server
	vncserver -geometry 1920x1080 -depth 16 :40
	;;
    ec) # start eclim server
	Xvfb :1 -screen 0 1024x768x24&
	DISPLAY=:1 /mnt/eclipse/eclimd
	;;
    ze) # set unused space to zeros
	cat /dev/zero > file.zero ; sync ; rm file.zero
	;;
    xk) # xorg keyboard setting
	echo "xorg keyboard"
	setxkbmap -option caps:ctrl_modifier
	xkbcomp xkb.dump $DISPLAY
	;;
    vm) # initialize vmware
	xrdb -merge .Xresources
	setxkbmap -option caps:ctrl_modifier
	xkbcomp xkb.dump $DISPLAY
	/usr/bin/vmware-user-suid-wrapper
	export DOTNET_CLI_TELEMETRY_OPTOUT true
	;;
    clean) # clean up system
	cleanup_system
	;;
    *)
	echo "Unknown command: $1"
        # show usage
	grep "\w) #" ~/do.sh | head --lines=-1 | sed 's/) #/ -/' | sort
	;;
esac

