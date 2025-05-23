# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} )

inherit distutils-r1 pypi

DESCRIPTION="Funtoo's franken-chroot tool"
HOMEPAGE="https://pypi.org/project/fchroot/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64 ~x86"

RDEPEND=""
DEPEND="${RDEPEND}"

#FIXME:
#QEMU_USER_TARGETS="aarch64 arm"
#app-emulation/qemu[qemu_targets_aarch64(+)]
#app-emulation/qemu static-user
#dev-libs/glib static-libs
#sys-apps/attr static-libs
#sys-libs/zlib static-libs
#dev-libs/libpcre static-libs
