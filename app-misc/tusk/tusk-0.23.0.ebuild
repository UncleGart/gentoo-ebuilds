# Copyright 1999-2024 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker desktop xdg-utils

DESCRIPTION="Refined Evernote desktop app"
HOMEPAGE="https://github.com/klaudiosinani/tusk"
SRC_URI="
	amd64? ( https://github.com/klaudiosinani/tusk/releases/download/v${PV}/tusk_${PV}_amd64.deb -> ${P}-amd64.deb )
	x86? ( https://github.com/klaudiosinani/tusk/releases/download/v${PV}/tusk_${PV}_i386.deb -> ${P}-i386.deb )
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

S="${WORKDIR}"

RDEPEND="
	x11-libs/libnotify
	x11-libs/libXtst
	x11-libs/libXScrnSaver
	>=dev-libs/nss-3
	"

QA_PREBUILT="
		opt/Tusk/libffmpeg.so
		opt/Tusk/libnode.so
		opt/Tusk/tusk"

src_unpack() {
	unpack_deb "${A}"
}

src_install() {
	domenu "${S}/usr/share/applications/tusk.desktop"

	doicon "${S}/usr/share/icons/hicolor/0x0/apps/tusk.png"

	dodoc usr/share/doc/tusk/changelog.gz

	insinto /
	doins -r opt
	fperms +x /opt/Tusk/${PN}
	dosym /opt/Tusk/${PN} /opt/bin/${PN}
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}
