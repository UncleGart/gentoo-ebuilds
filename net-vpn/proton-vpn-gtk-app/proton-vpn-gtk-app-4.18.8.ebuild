# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit desktop distutils-r1 xdg

DESCRIPTION="Proton VPN GTK app"
HOMEPAGE="https://github.com/ProtonVPN/proton-vpn-gtk-app"
SRC_URI="https://github.com/ProtonVPN/proton-vpn-gtk-app/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="split-tunneling"
RESTRICT="test"

RDEPEND="
	gnome-base/librsvg
	gui-libs/gtk:4[introspection]
	net-misc/networkmanager[introspection]
	x11-libs/libnotify[introspection]
	$(python_gen_cond_dep '
		dev-python/dbus-python[${PYTHON_USEDEP}]
		dev-python/distro[${PYTHON_USEDEP}]
		dev-python/packaging[${PYTHON_USEDEP}]
		>=dev-python/proton-core-0.5.0[${PYTHON_USEDEP}]
		dev-python/proton-keyring-linux[${PYTHON_USEDEP}]
		>=dev-python/proton-vpn-api-core-5.8.1[${PYTHON_USEDEP}]
		dev-python/pycairo[${PYTHON_USEDEP}]
		dev-python/pygobject:3[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
	')
	split-tunneling? ( net-vpn/proton-vpn-daemon[${PYTHON_SINGLE_USEDEP}] )
"
# msgfmt compiles the translations during build_py
BDEPEND="sys-devel/gettext"

src_prepare() {
	distutils-r1_src_prepare

	sed -i "/--cov/d" setup.cfg || die
}

src_install() {
	distutils-r1_src_install

	doicon rpmbuild/SOURCES/proton-vpn-logo.svg
	domenu rpmbuild/SOURCES/proton.vpn.app.gtk.desktop
}

pkg_postinst() {
	xdg_pkg_postinst

	if use split-tunneling; then
		elog "Split tunneling is provided by net-vpn/proton-vpn-daemon; see its"
		elog "post-install notes for enabling the system service."
	fi
}
