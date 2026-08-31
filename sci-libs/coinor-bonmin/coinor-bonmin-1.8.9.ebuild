# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN=Bonmin

DESCRIPTION="COIN-OR Basic Open-source Nonlinear Mixed INteger programming"
HOMEPAGE="https://github.com/coin-or/Bonmin/"
SRC_URI="https://github.com/coin-or/${MY_PN}/archive/releases/${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/${MY_PN}-releases-${PV}/${MY_PN}"

LICENSE="EPL-1.0"
SLOT="0/4"
KEYWORDS="~amd64 ~x86"
IUSE="doc test"
RESTRICT="!test? ( test )"

RDEPEND="
	sci-libs/coinor-cbc:=
	sci-libs/coinor-cgl:=
	sci-libs/coinor-clp:=
	sci-libs/coinor-osi:=
	sci-libs/coinor-utils:=
	sci-libs/ipopt:=
	virtual/blas"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	doc? (
		app-text/doxygen[dot]
		virtual/latex-base
	)
	test? ( sci-libs/coinor-sample )"

src_configure() {
	local myeconfargs=(
		--without-filtersqp
		$(use_with doc dot)
	)

	econf "${myeconfargs[@]}"
}

src_compile() {
	emake all $(usex doc doxydoc '')
}

src_test() {
	# Needed given "make check" is a noop and it skips the working one.
	emake test
}

src_install() {
	default
	dodoc -r examples doc/BONMIN_UsersManual.pdf
	use doc && dodoc -r doxydoc/html

	# Duplicate or irrelevant files.
	rm -r "${ED}"/usr/share/coin/doc || die
	find "${ED}" -name '*.la' -delete || die
}
