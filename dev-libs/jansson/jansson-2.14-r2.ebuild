# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools multilib-minimal

DESCRIPTION="C library for encoding, decoding and manipulating JSON data"
HOMEPAGE="https://www.digip.org/jansson/"
SRC_URI="https://github.com/akheron/jansson/releases/download/v${PV}/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0/4"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~x64-macos"
IUSE="doc static-libs"

BDEPEND="
	dev-build/autoconf-archive
	doc? ( dev-python/sphinx )
"

PATCHES=(
	"${FILESDIR}/${P}-default-symver-test.patch"
	"${FILESDIR}/${P}-test-symbols.patch"
)

src_prepare() {
	default
	eautoreconf
	multilib_copy_sources
}

multilib_src_configure() {
	econf $(use_enable static-libs static)
}

multilib_src_compile() {
	default

	if use doc ; then
		emake html
		HTML_DOCS=( doc/_build/html/. )
	fi
}

multilib_src_install() {
	default

	find "${ED}" -name '*.la' -delete || die
}