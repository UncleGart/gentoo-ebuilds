# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit cmake python-any-r1 multilib-minimal

DESCRIPTION="a fast cryptographic hash function"
HOMEPAGE="https://github.com/BLAKE3-team/BLAKE3"
SRC_URI="https://github.com/BLAKE3-team/BLAKE3/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/BLAKE3-${PV}/c"

LICENSE="|| ( CC0-1.0 Apache-2.0 )"
SLOT="0/0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~arm64-macos ~x64-macos"
IUSE="test"
RESTRICT="!test? ( test )"

BDEPEND="test? ( ${PYTHON_DEPS} )"

PATCHES=( "${FILESDIR}/${PN}-1.5.3-backport-pr405.patch" )

pkg_setup() {
	use test && python-any-r1_pkg_setup
}

# src_prepare() {
# 	default
# 	cmake_src_prepare
# 	multilib_copy_sources
# }

multilib_src_configure() {
	local mycmakeargs=(
		$(usev abi_x86_x32 -DBLAKE3_SIMD_TYPE="x86-intrinsics")
		-DBLAKE3_BUILD_TESTING="$(usex test)"
		-DBLAKE3_USE_TBB=OFF # TODO
	)
	cmake_src_configure
}

multilib_src_compile() {
	default
	cmake_src_compile
}

multilib_src_install() {
	cmake_src_install
}