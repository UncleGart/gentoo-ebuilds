# Copyright 1999-2026 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="cmdline"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="A simple tool to generate a kernel cmdline string from /etc/cmdline and /etc/cmdline.d/"
HOMEPAGE="https://github.com/jrouleau/${MY_PN}"
SRC_URI="https://github.com/jrouleau/${MY_PN}/archive/refs/tags/v${PV}.tar.gz"
S="${WORKDIR}/${MY_P}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

# Dependencies
RDEPEND="app-shells/bash"
DEPEND="${RDEPEND}"

src_compile() {
    :
}

src_install() {
    # Install the script
    dobin gencmdline
    dodoc README.md
}