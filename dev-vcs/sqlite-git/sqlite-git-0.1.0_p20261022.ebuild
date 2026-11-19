# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit multilib toolchain-funcs

DESCRIPTION="Git object, ref and git-lfs storage in SQLite"
HOMEPAGE="https://github.com/MayCXC/sqlite-git"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/MayCXC/sqlite-git.git"
else
	COMMIT="038e20cc9cd8417231df0feab6d9a76130e0782e"
	SRC_URI="https://github.com/MayCXC/sqlite-git/archive/${COMMIT}.tar.gz -> ${P}.gh.tar.gz"
	S="${WORKDIR}/${PN}-${COMMIT}"
	KEYWORDS="~amd64"
fi

LICENSE="BSD
	gitlfs? ( public-domain )
	git-lfs-sqlite-transfer? ( public-domain )
"
SLOT="0"
IUSE="+git0 git-local-sqlite +gitlfs +git-lfs-sqlite-transfer test"
REQUIRED_USE="|| ( git0 git-local-sqlite gitlfs git-lfs-sqlite-transfer )"
RESTRICT="!test? ( test )"

DEPEND="
	>=dev-db/sqlite-3.41.0:3
	git0? (
		dev-libs/libgit2:=
		virtual/zlib:=
	)
	git-local-sqlite? ( virtual/zlib:= )
"
RDEPEND="
	${DEPEND}
	git-lfs-sqlite-transfer? ( dev-vcs/git-lfs )
"
BDEPEND="
	git0? ( virtual/pkgconfig )
	test? ( dev-vcs/git )
"

PATCHES=(
	"${FILESDIR}"/${PN}-0.1.0-libgit2-flags.patch
)

src_compile() {
	local targets=()
	use git0 && targets+=( build/stock/git0$(get_libname) )
	use git-local-sqlite && targets+=( git-local-sqlite )
	use gitlfs && targets+=( build/gitlfs$(get_libname) )
	use git-lfs-sqlite-transfer && targets+=( git-lfs-sqlite-transfer )

	local myemakeargs=(
		CC="$(tc-getCC)"
		CFLAGS="${CFLAGS} -fPIC"
		LDFLAGS="${LDFLAGS}"
	)
	if use git0; then
		myemakeargs+=(
			LIBGIT2_CFLAGS="$($(tc-getPKG_CONFIG) --cflags libgit2)"
			LIBGIT2_LIBS="$($(tc-getPKG_CONFIG) --libs libgit2)"
		)
	fi

	emake "${myemakeargs[@]}" "${targets[@]}"
}

src_test() {
	# Upstream's "make test" is not usable here.
	if use git-local-sqlite && use git-lfs-sqlite-transfer; then
		sh tests/test_helper.sh || die "test_helper.sh failed"
	else
		ewarn "Skipping tests/test_helper.sh: it needs both USE=git-local-sqlite"
		ewarn "and USE=git-lfs-sqlite-transfer."
	fi

	if use git0; then
		local t
		for t in concurrent object_format reflog vtab; do
			GIT0="${S}/build/stock/git0" sh tests/test_${t}.sh \
				|| die "test_${t}.sh failed"
		done
	fi

	if use gitlfs; then
		sqlite3 "${T}"/gitlfs-test.db -cmd ".load ${S}/build/gitlfs" \
			< tests/test_lfs.sql || die "test_lfs.sql failed"
	fi
}

src_install() {
	exeinto /usr/$(get_libdir)
	use git0 && doexe build/stock/git0$(get_libname)
	use gitlfs && doexe build/gitlfs$(get_libname)

	use git-local-sqlite && dobin git-local-sqlite
	use git-lfs-sqlite-transfer && dobin git-lfs-sqlite-transfer

	einstalldocs
}

pkg_postinst() {
	if use git0 || use gitlfs; then
		elog "Load the SQLite extensions with:"
		use git0 && elog "  sqlite> .load git0      (or SELECT load_extension('git0');)"
		use gitlfs && elog "  sqlite> .load gitlfs    (or SELECT load_extension('gitlfs');)"
		elog
	fi
	if use git-local-sqlite; then
		elog "git-local-sqlite needs a git that speaks the local-helper protocol"
		elog "(extensions.objectstorage / extensions.refstorage = helper://sqlite)."
		elog "Stock dev-vcs/git does not yet; see https://github.com/MayCXC/git"
		elog
	fi
	if use git-lfs-sqlite-transfer; then
		elog "To store a repository's LFS content in <gitdir>/sqlite.db:"
		elog "  git config lfs.customtransfer.sqlite.path git-lfs-sqlite-transfer"
		elog "  git config lfs.customtransfer.sqlite.args .git"
		elog "  git config lfs.standalonetransferagent sqlite"
	fi
}
