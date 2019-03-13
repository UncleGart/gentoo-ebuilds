# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit vcs-snapshot cmake-utils systemd

DESCRIPTION="Corsair K65/K70/K95 Driver"
HOMEPAGE="https://github.com/ckb-next/ckb-next"
SRC_URI="https://github.com/ckb-next/ckb-next/archive/v${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtnetwork:5
	dev-qt/qtwidgets:5"
RDEPEND="${DEPEND}"

#DOCS=( README.md DAEMON.md )
CMAKE_BUILD_TYPE=Release

src_unpack() {
	unpack ${A}
	cd "${WORKDIR}"
	mv ckb-next-${PV} ${P}
}

