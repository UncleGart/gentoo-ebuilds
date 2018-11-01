# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python3_{4,5,6} )

if [[ ${PV} == 9999* ]]; then
	EGIT_REPO_URI="https://github.com/UncleGart/${PN}.git"
	EGIT_BRANCH="sorted-results"
	inherit distutils-r1 git-r3
else
	SRC_URI="https://github.com/fedeliallalinea/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	inherit distutils-r1
fi

DESCRIPTION="Search and download package ebuilds from gpo.zugaina.org"
HOMEPAGE="https://github.com/fedeliallalinea/gpo-zugaina-dl"
LICENSE="GPL-2"
SLOT="0"

RDEPEND="
        dev-python/beautifulsoup:4[${PYTHON_USEDEP}]
        dev-python/urllib3[${PYTHON_USEDEP}]"
DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
