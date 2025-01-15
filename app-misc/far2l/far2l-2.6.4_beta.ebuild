# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#CMAKE_MAKEFILE_GENERATOR ?= ninja
CMAKE_MAKEFILE_GENERATOR=emake
CMAKE_IN_SOURCE_BUILD=1
CMAKE_BUILD_TYPE=Release

inherit cmake xdg-utils

DESCRIPTION="Linux port of FAR v2"
MY_PV="v_${PV/_beta/}"
MY_P="${PN}-${MY_PV}"
S="${WORKDIR}/${MY_P}"
HOMEPAGE="https://github.com/elfmz/far2l/"
SRC_URI="https://github.com/elfmz/far2l/archive/refs/tags/${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
KEYWORDS="amd64 arm64 x86"

LICENSE="GPL-2"
SLOT="0"
IUSE="+uchardet X +ssh nfs +samba webdav"

DEPEND="
	dev-libs/xerces-c
	uchardet? ( app-i18n/uchardet )
	dev-build/cmake
	dev-libs/spdlog

	X? ( x11-libs/wxGTK )
	webdav? ( net-libs/neon )
	ssh? ( net-libs/libssh )
	nfs? ( net-fs/libnfs )
	samba? ( net-fs/samba )
"
RDEPEND="${DEPEND}"

# PATCHES=(
# 	"${FILESDIR}"/${PN}-2.6.3-time_t.patch
# )

src_configure() {
	#FIXME: more options:
	# -DPYTHON=yes
	#ALIGN AUTOWRAP CALC COLORER COMPARE DRAWLINE EDITCASE EDITORCOMP FARFTP
	#FILECASE INCSRCH INSIDE MULTIARC NETROCKS SIMPLEINDENT TMPPANEL

	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=OFF
		-DUSEWX=$(usex X yes no)
		# automatic charset detection
		-DUSEUCD=$(usex uchardet yes no)
	)
	cmake_src_configure
}

src_install() {
	emake DESTDIR="${D}" install

	newbin - far <<-EOF
		#!/bin/sh
		/usr/bin/far2l "\$@" --tty
	EOF
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}