# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit base eutils user systemd git-r3 autotools

DESCRIPTION="icecc is a program for distributed compiling of C(++) code across several machines; based on distcc"
HOMEPAGE="https://github.com/icecc/icecream"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~sparc ~x86"
IUSE="systemd"

RDEPEND="
	dev-libs/lzo
	sys-libs/libcap-ng
	app-text/docbook2X
"
DEPEND="${RDEPEND}"

EGIT_REPO_URI="https://github.com/icecc/icecream.git"
REFS="e39103ff5fb6aa7e939b486df25d621696ba1d6f"
TAG="${PV}"

pkg_setup() {
	enewgroup icecream
	enewuser icecream -1 -1 /var/cache/icecream icecream
}

src_unpack() {
	git-r3_fetch ${EGIT_REPO_URI} ${REFS} ${TAG}
	git-r3_checkout ${EGIT_REPO_URI} ${WORKDIR}/${P} ${TAG} 
}

src_prepare() {
	eautoreconf
}

src_configure() {
	econf \
		--enable-shared --disable-static \
		--enable-clang-wrappers \
		--enable-clang-rewrite-includes
}

src_install() {
	default
	prune_libtool_files --all

	newconfd suse/sysconfig.icecream icecream
	newinitd "${FILESDIR}"/icecream-r2 icecream

	insinto /etc/logrotate.d
	newins suse/logrotate icecream

	exeinto /usr/libexec/icecc
	doexe "${FILESDIR}"/iceccd-wrapper
	doexe "${FILESDIR}"/icecc-scheduler-wrapper

	if use systemd ; then
		systemd_dounit "${FILESDIR}/iceccd.service"
		systemd_dounit "${FILESDIR}/icecc-scheduler.service"
	fi
}
