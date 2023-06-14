# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A command line client for tldr, written in plain ISO C90"
HOMEPAGE="https://github.com/tldr-pages/tldr-c-client"
SRC_URI="https://github.com/tldr-pages/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	net-misc/curl
	dev-libs/libzip
"
RDEPEND="
	${DEPEND}
"

BDEPEND="virtual/pkgconfig"

src_install() {
	emake PREFIX="${D}" install
}
