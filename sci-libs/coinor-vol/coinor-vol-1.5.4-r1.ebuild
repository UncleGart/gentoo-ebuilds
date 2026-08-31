# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN=Vol

DESCRIPTION="COIN-OR volume algorithm linear program solver"
HOMEPAGE="https://github.com/coin-or/Vol/"
SRC_URI="https://github.com/coin-or/${MY_PN}/archive/releases/${PV}.tar.gz
	-> ${P}.tar.gz"
S="${WORKDIR}/${MY_PN}-releases-${PV}/${MY_PN}"

LICENSE="EPL-1.0"

# major soname component
SLOT="0/1"

KEYWORDS="~amd64 ~loong ~riscv ~x86"
IUSE="doc examples static-libs test"
RESTRICT="!test? ( test )"

BDEPEND="virtual/pkgconfig
	doc? ( app-text/doxygen[dot] )
	test? ( sci-libs/coinor-sample )"

DEPEND="sci-libs/coinor-osi:=
	sci-libs/coinor-utils:="
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}"/${PN}-1.5.4-musl-1.2.3-null.patch
)

src_prepare() {
	# Needed to make the --with-coin-instdir in src_configure happy.
	dodir /usr

	# They don't need to guess at this, but they do, and get it wrong...
	sed -e "s:lib/pkgconfig:$(get_libdir)/pkgconfig:g" \
		-i configure \
		|| die "failed to fix the pkgconfig path in ${S}/configure"

	default
}

src_configure() {
	local myeconfargs=(
		--enable-dependency-linking
		--with-coin-instdir="${ED}/usr"
		$(use_enable static-libs static)
		$(use_with doc dot)
	)

	econf "${myeconfargs[@]}"
}

src_compile() {
	emake all $(usex doc doxydoc "")
}

src_test() {
	# NOT redundant! The build system has a "make check" target that does
	# nothing, so if you don't specify "test" here, you'll get a no-op.
	emake test
}

src_install() {
	emake DESTDIR="${D}" install

	# The doxygen output; the old HTML_DOC= incantation was a no-op
	# leftover from EAPI 5 and silently installed nothing.
	use doc && dodoc -r doxydoc/html

	# Duplicate junk, and in the wrong location.
	rm -r "${ED}/usr/share/coin/doc/${MY_PN}" || die

	# Portage still throws a warning for these, but it's a bug
	# as far as I can tell: https://bugs.gentoo.org/721516
	docompress -x "/usr/share/doc/${PF}/examples/Volume-LP/data.mps.gz"
	docompress -x "/usr/share/doc/${PF}/examples/VolUfl/data.gz"
	use examples && dodoc -r examples

	find "${ED}" -name '*.la' -delete || die
}
