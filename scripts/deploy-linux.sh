#!/bin/sh

# Run make install
make install DESTDIR=appdir
cp /usr/bin/ffmpeg ./appdir/usr/bin/

# Create appimage
export VERSION=${TRAVIS_TAG#v}

glibc_ver=$(ldd --version | sed -n "1s/^.* \([0-9.]*\)$/\1/p")
if [ ${glibc_ver#*.} -ge 27 ]; then
    no_check_glibc="-unsupported-allow-new-glibc"
    copyright="/usr/share/doc/libc6/copyright"
    install -p -T -D "$copyright" "appdir$copyright"
fi

if [ ! -x linuxdeployqt.AppImage ]; then
    curl -Lo linuxdeployqt.AppImage "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
    chmod a+x linuxdeployqt.AppImage
fi

wl_plugins="\
platforms/libqwayland-generic.so,\
platforms/libqwayland-egl.so,\
wayland-shell-integration/libxdg-shell.so,\
wayland-shell-integration/libxdg-shell-v6.so,\
wayland-decoration-client/libbradient.so,\
wayland-graphics-integration-client/libqt-plugin-wayland-egl.so"

exclude_libs="\
libnsl.so.1,\
libbsd.so.0,\
libnuma.so.1,\
libselinux.so.1,\
libsystemd.so.0,\
libtasn1.so.6,\
libgcrypt.so.20,\
libidn.so.11,\
libasyncns.so.0,\
libwrap.so.0,\
libgnutls.so.30,\
libuchardet.so.0,\
libpcre.so.3,\
libbz2.so.1.0,\
liblzma.so.5,\
libxml2.so.2,\
libgthread-2.0.so.0,\
libdbus-1.so.3,\
libpulse.so.0,\
liblcms2.so.2,libgraphite2.so.3,libjpeg.so.8,libopenjp2.so.7,\
libxkbcommon.so.0,libxkbcommon-x11.so.0,\
libX11-xcb.so.1,libxcb-glx.so.0,libxcb-present.so.0,libxcb-shape.so.0,libxcb-shm.so.0,libxcb-sync.so.1,libxcb-xfixes.so.0,libxcb-xkb.so.1,\
libXau.so.6,libXcursor.so.1,libXdamage.so.1,libXdmcp.so.6,libXext.so.6,libXfixes.so.3,libXinerama.so.1,libXi.so.6,libXrandr.so.2,libXrender.so.1,libxshmfence.so.1,libXss.so.1,libxvidcore.so.4,libXv.so.1,libXxf86vm.so.1,\
libwayland-client.so.0,libwayland-cursor.so.0,libwayland-egl.so.1,libwayland-server.so.0,\
libvorbisenc.so.2,libvorbis.so.0,libogg.so.0,\
libtwolame.so.0,libmp3lame.so.0,libFLAC.so.8,libopus.so.0,libwavpack.so.1,libspeex.so.1,libgsm.so.1,libsndfile.so.1,\
libavc1394.so.0,librom1394.so.0,libraw1394.so.11,\
libiec61883.so.0,libtheoradec.so.1,libtheoraenc.so.1"

exec ./linuxdeployqt.AppImage appdir/usr/share/applications/*.desktop $no_check_glibc -appimage -qmldir=src/qml/ -executable=appdir/usr/bin/ffmpeg -executable=appdir/usr/bin/moonplayer-hlsdl -exclude-libs="$exclude_libs" -extra-plugins="$wl_plugins"
