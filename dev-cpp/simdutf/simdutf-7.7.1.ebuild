# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DOCS_BUILDER="doxygen"
DOCS_DIR=""

PYTHON_COMPAT=( python3_{11..14} )

inherit docs python-any-r1 cmake-multilib

DESCRIPTION="Unicode validation and transcoding at billions of characters per second"
HOMEPAGE="https://simdutf.github.io/simdutf/"
SRC_URI="https://github.com/${PN}/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="|| ( Apache-2.0 MIT )"
SLOT="0/25"
KEYWORDS="amd64 ~arm arm64 ~loong ~ppc ~ppc64 ~riscv ~x86"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	virtual/libiconv
"
DEPEND="${RDEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	virtual/pkgconfig
	doc? (
		app-text/doxygen
	)
"

multilib_src_configure(){
	local mycmakeargs+=(
		-DSIMDUTF_TESTS=$(usex test)
		-DSIMDUTF_ATOMIC_BASE64_TESTS=$(usex test)
	)
	cmake_src_configure
}

multilib_src_compile() {
	cmake_src_compile
	use doc && docs_compile
}

multilib_src_install() {
	cmake_src_install
	use doc && einstalldocs
}
