# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="C++ engine for simulating rigid bodies in 2D games"
HOMEPAGE="https://box2d.org/"
SRC_URI="https://github.com/erincatto/Box2D/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="amd64 ~arm arm64 ~loong ppc64 ~riscv x86"
IUSE="doc test"
RESTRICT="!test? ( test )"

DEPEND="test? ( dev-cpp/doctest )"
BDEPEND="doc? ( app-text/doxygen )"

MY_P="${P}"

PATCHES=(
	"${FILESDIR}"/${MY_P}-remove_enkiTS_fetch.patch
)

src_configure() {
	local mycmakeargs=(
		-DBOX2D_BUILD_TESTBED=OFF # bundled libs, broken anyway right now
		-DBOX2D_BUILD_UNIT_TESTS=$(usex test)
		-DBOX2D_BUILD_DOCS=$(usex doc)
		-DBOX2D_SAMPLES=OFF
		-DBUILD_SHARED_LIBS=ON
	)
	cmake_src_configure
}

src_test() {
	"${BUILD_DIR}"/bin/unit_test || die
}

src_install() {
	cmake_src_install

	local pkgconfig_dir="/usr/$(get_libdir)/pkgconfig"
	dodir "${pkgconfig_dir}"
	sed \
		-e "s|@libdir@|$(get_libdir)|" \
		-e "s|@version@|${MY_PV}|" \
		"${FILESDIR}"/box2d.pc.in > \
		"${ED}${pkgconfig_dir}"/${PN}.pc || die
}
