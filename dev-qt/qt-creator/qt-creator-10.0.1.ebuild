# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
LLVM_MAX_SLOT=15

inherit cmake llvm optfeature virtualx xdg

DESCRIPTION="Lightweight IDE for C++/QML development centering around Qt"
HOMEPAGE="https://doc.qt.io/qtcreator/"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://code.qt.io/${PN}/${PN}.git"
	EGIT_SUBMODULES=(
		perfparser
		qtscript # Need the dev branch
		src/libs/qlitehtml
		src/libs/qlitehtml/src/3rdparty/litehtml
	)
else
	MY_PV=${PV/_/-}
	MY_P=${PN}-opensource-src-${MY_PV}
	[[ ${MY_PV} == ${PV} ]] && MY_REL=official || MY_REL=development
	SRC_URI="https://download.qt.io/${MY_REL}_releases/${PN/-}/$(ver_cut 1-2)/${MY_PV}/${MY_P}.tar.xz"
	S="${WORKDIR}"/${MY_P}
	KEYWORDS="~amd64 ~arm ~x86"
fi

LICENSE="GPL-3"
SLOT="0"

QTCREATOR_PLUGINS=(
	# Misc
	+autotest beautifier coco conan cppcheck ctfvisualizer docker
	imageviewer modeling perfprofiler qmlprofiler scxml serialterminal
	silversearcher valgrind

	# Buildsystems
	autotools +cmake incredibuild meson qbs +qmake

	# Languages
	glsl +lsp nim python

	# Platforms
	android baremetal boot2qt mcu qnx remotelinux webassembly

	# VCS
	bazaar clearcase cvs +git mercurial perforce subversion
)

IUSE="+clang debug doc +qml systemd wayland webengine
	${QTCREATOR_PLUGINS[@]}"

REQUIRED_USE="
	android? ( lsp )
	boot2qt? ( remotelinux )
	clang? ( lsp )
	coco? ( lsp )
	mcu? ( baremetal cmake )
	python? ( lsp )
	qml? ( qmake )
	qnx? ( remotelinux )
"

# minimum Qt version required
QT_PV="6.2"

CDEPEND="
	clang? (
		>=dev-cpp/yaml-cpp-0.6.2:=
		sys-devel/clang:${LLVM_MAX_SLOT}=
	)
	>=dev-qt/qtbase-${QT_PV}
	>=dev-qt/qt5compat-${QT_PV}

	imageviewer? ( >=dev-qt/qtsvg-${QT_PV} )
	perfprofiler? (
		app-arch/zstd
		dev-libs/elfutils
	)
	serialterminal? ( >=dev-qt/qtserialport-${QT_PV} )
	systemd? ( sys-apps/systemd:= )
"
DEPEND="
	${CDEPEND}
"
RDEPEND="
	${CDEPEND}
	qml? ( >=dev-qt/qtquicktimeline-${QT_PV} )
	wayland? ( >=dev-qt/qtgui-${QT_PV}[wayland] )
"

# FUNCTION: cmake_use_remove_addsubdirectory
# USAGE: <flag> <subdir> <files...>
# DESCRIPTION:
# <flag> is the name of a flag in IUSE.
# <subdir> is the  name of a directory called with add_subdirectory().
# <files...> is a list of one or more qmake project files.
#
# This function patches <files> to remove add_subdirectory(<subdir>) from cmake
# when <flag> is disabled, otherwise it does nothing. This can be useful to
# avoid an automagic dependency when a subdirectory is added in cmake but the
# corresponding feature USE flag is disabled. Similar to qt_use_disable_config()
# from /qt5-build.eclass
cmake_use_remove_addsubdirectory() {
	[[ $# -ge 3 ]] || die "${FUNCNAME}() requires at least three arguments"
	local flag=$1
	local subdir=$2
	shift 2

	if ! use "${flag}"; then
		echo "$@" | xargs sed -i -e "/add_subdirectory(${subdir})/d" || die
	fi
}

llvm_check_deps() {
	has_version -d "sys-devel/clang:${LLVM_SLOT}"
}

pkg_setup() {
	if use clang; then
		llvm_pkg_setup
		export CLANG_PREFIX="$(get_llvm_prefix ${LLVM_MAX_SLOT})"
	fi
}

src_prepare() {
	cmake_src_prepare

	# PLUGIN_RECOMMENDS is treated like a hard-dependency
	sed -i -e '/PLUGIN_RECOMMENDS /d' \
		src/plugins/*/CMakeLists.txt || die

	cmake_use_remove_addsubdirectory glsl glsl src/libs/CMakeLists.txt
	cmake_use_remove_addsubdirectory lsp languageserverprotocol \
		src/libs/CMakeLists.txt tests/auto/CMakeLists.txt
	cmake_use_remove_addsubdirectory modeling modelinglib \
		src/libs/CMakeLists.txt
	cmake_use_remove_addsubdirectory qml advanceddockingsystem \
		src/libs/CMakeLists.txt
	cmake_use_remove_addsubdirectory clang clangtools \
		src/plugins/CMakeLists.txt
	cmake_use_remove_addsubdirectory test test \
		src/plugins/mcusupport/CMakeLists.txt

	# remove bundled yaml-cpp
	rm -r src/libs/3rdparty/yaml-cpp || die

	# remove bundled qbs
	rm -r src/shared/qbs || die

	# qt-creator hardcodes the CLANG_INCLUDE_DIR to the default.
	# However, in sys-devel/clang, the directory changes with respect to
	# -DCLANG_RESOURCE_DIR.  We sed in the correct include dir.
	if use clang; then
		local res_dir="$(${CLANG_PREFIX}/bin/clang -print-resource-dir || die)"
		sed -i -e "/\w*CLANG_INCLUDE_DIR=/s|=.*|=\"${res_dir}/include\"|" \
			src/plugins/clangtools/CMakeLists.txt || die
	fi
}

src_configure() {
	mycmakeargs+=(
		-DWITH_DEBUG_CMAKE=$(usex debug)

		# Don't use SANITIZE_FLAGS to pass extra CXXFLAGS
		-DWITH_SANITIZE=NO

		# Prefer bundled ksyntaxhighlighting due to potential Qt version mismatch
		-DBUILD_LIBRARY_KSYNTAXHIGHLIGHTING=YES

		# Install failure.  Disable for now
		-DWITH_ONLINE_DOCS=NO

		# Force enable plugins that pride basic, neccessary IDE functionality
		# and small, simple plugins
		-DBUILD_PLUGIN_BINEDITOR=YES
		-DBUILD_PLUGIN_BOOKMARKS=YES
		-DBUILD_PLUGIN_CLASSVIEW=YES
		-DBUILD_PLUGIN_CODEPASTER=YES
		-DBUILD_PLUGIN_COMPILATIONDATABASEPROJECTMANAGER=YES
		-DBUILD_PLUGIN_CORE=YES
		-DBUILD_PLUGIN_CPPEDITOR=YES
		-DBUILD_PLUGIN_DEBUGGER=YES
		-DBUILD_PLUGIN_DIFFEDITOR=YES
		-DBUILD_PLUGIN_EMACSKEYS=YES
		-DBUILD_PLUGIN_FAKEVIM=YES
		-DBUILD_PLUGIN_GENERICPROJECTMANAGER=YES
		-DBUILD_PLUGIN_MACROS=YES
		-DBUILD_PLUGIN_MARKETPLACE=YES
		-DBUILD_PLUGIN_PROJECTEXPLORER=YES
		-DBUILD_PLUGIN_QMLJSTOOLS=YES
		-DBUILD_PLUGIN_QTSUPPORT=YES
		-DBUILD_PLUGIN_RESOURCEEDITOR=YES
		-DBUILD_PLUGIN_TASKLIST=YES
		-DBUILD_PLUGIN_TEXTEDITOR=YES
		-DBUILD_PLUGIN_TODO=YES
		-DBUILD_PLUGIN_VCSBASE=YES
		-DBUILD_PLUGIN_WELCOME=YES

		# Misc
		-DBUILD_PLUGIN_AUTOTEST=$(usex autotest)
		-DBUILD_PLUGIN_BEAUTIFIER=$(usex beautifier)
		-DBUILD_PLUGIN_COCO=$(usex coco)
		-DBUILD_PLUGIN_CONAN=$(usex conan)
		-DBUILD_PLUGIN_CPPCHECK=$(usex cppcheck)
		-DBUILD_PLUGIN_CTFVISUALIZER=$(usex ctfvisualizer)
		-DBUILD_PLUGIN_DOCKER=$(usex docker)
		-DBUILD_PLUGIN_IMAGEVIEWER=$(usex imageviewer)
		-DBUILD_PLUGIN_MODELEDITOR=$(usex modeling)
		-DBUILD_PLUGIN_PERFPROFILER=$(usex perfprofiler)
		-DBUILD_PLUGIN_QMLPROFILER=$(usex qmlprofiler)
		-DBUILD_PLUGIN_SCXMLEDITOR=$(usex scxml)
		-DBUILD_PLUGIN_SERIALTERMINAL=$(usex serialterminal)
		-DBUILD_PLUGIN_SILVERSEARCHER=$(usex silversearcher)
		-DBUILD_PLUGIN_VALGRIND=$(usex valgrind)

		# Buildsystems
		-DBUILD_PLUGIN_AUTOTOOLSPROJECTMANAGER=$(usex autotools)
		-DBUILD_PLUGIN_CMAKEPROJECTMANAGER=$(usex cmake)
		-DBUILD_PLUGIN_MESONPROJECTMANAGER=$(usex meson)
		-DBUILD_PLUGIN_QBSPROJECTMANAGER=$(usex qbs)
		-DBUILD_PLUGIN_QMAKEPROJECTMANAGER=$(usex qmake)

		# Languages
		-DBUILD_PLUGIN_GLSLEDITOR=$(usex glsl)
		-DBUILD_PLUGIN_LANGUAGECLIENT=$(usex lsp)
		-DBUILD_PLUGIN_NIM=$(usex nim)
		-DBUILD_PLUGIN_PYTHON=$(usex python)

		# Platforms
		-DBUILD_PLUGIN_ANDROID=$(usex android)
		-DBUILD_PLUGIN_BAREMETAL=$(usex baremetal)
		-DBUILD_PLUGIN_BOOT2QT=$(usex boot2qt)
		-DBUILD_PLUGIN_MCUSUPPORT=$(usex mcu)
		-DBUILD_PLUGIN_QNX=$(usex qnx)
		-DBUILD_PLUGIN_REMOTELINUX=$(usex remotelinux)
		-DBUILD_PLUGIN_WEBASSEMBLY=$(usex webassembly)

		# VCS
		-DBUILD_PLUGIN_BAZAAR=$(usex bazaar)
		-DBUILD_PLUGIN_CLEARCASE=$(usex clearcase)
		-DBUILD_PLUGIN_CVS=$(usex cvs)
		-DBUILD_PLUGIN_GIT=$(usex git)
		-DBUILD_PLUGIN_GITLAB=$(usex git)
		-DBUILD_PLUGIN_MERCURIAL=$(usex mercurial)
		-DBUILD_PLUGIN_PERFORCE=$(usex perforce)
		-DBUILD_PLUGIN_SUBVERSION=$(usex subversion)

		# Executables
		-DBUILD_EXECUTABLE_BUILDOUTPUTPARSER=$(usex qmake)
		-DBUILD_EXECUTABLE_PERFPARSER=$(usex perfprofiler)
		-DBUILD_EXECUTABLE_QML2PUPPET=$(usex qml)

		# Clang stuff
		-DBUILD_PLUGIN_CLANGCODEMODEL=$(usex clang)
		-DBUILD_PLUGIN_CLANGFORMAT=$(usex clang)

		# QML stuff
		-DBUILD_PLUGIN_QMLDESIGNER=$(usex qml) #Qt6 only
		-DBUILD_PLUGIN_QMLJSEDITOR=$(usex qml)
		-DBUILD_PLUGIN_QMLPREVIEW=$(usex qml)
		-DBUILD_PLUGIN_QMLPROJECTMANAGER=$(usex qml)
		-DBUILD_PLUGIN_STUDIOWELCOME=$(usex qml) #Qt6 only

		# Don't spam "created by a different GCC executable [-Winvalid-pch]"
		-DBUILD_WITH_PCH=NO
		# An entire mode devoted to a giant "Hello World!" button that does nothing.
		-DBUILD_PLUGIN_HELLOWORLD=NO
		# Not usable in linux environment
		-DBUILD_PLUGIN_IOS=NO
		# Use portage to update
		-DBUILD_PLUGIN_UPDATEINFO=NO
	)

	if use clang; then
		mycmakeargs+=(
			-DClang_DIR="${CLANG_PREFIX}/$(get_libdir)/cmake/clang"
			-DLLVM_DIR="${CLANG_PREFIX}/$(get_libdir)/cmake/llvm"
			-DCLANGTOOLING_LINK_CLANG_DYLIB=YES
			-DBUILD_PLUGIN_CLANGTOOLS=YES
		)
	fi
	cmake_src_configure
}

src_test() {
	virtx cmake_src_test
}

src_install() {
	cmake_src_install
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature_header \
		"Some enabled plugins require optional dependencies for functionality:"
	use android && optfeature "android device support" \
		dev-util/android-sdk-update-manager
	if use autotest; then
		optfeature "catch testing framework support" dev-cpp/catch
		optfeature "gtest testing framework support" dev-cpp/gtest
		optfeature "boost testing framework support" dev-libs/boost
		optfeature "qt testing framework support" dev-qt/qttest
	fi
	if use beautifier; then
		optfeature "astyle auto-formatting support" dev-util/astyle
		optfeature "uncrustify auto-formatting support" dev-util/uncrustify
	fi
	use clang && optfeature "clazy QT static code analysis" dev-util/clazy
	use conan && optfeature "conan package manager integration" dev-util/conan
	use cvs && optfeature "cvs vcs integration" dev-vcs/cvs
	use docker && optfeature "using a docker image as a device" \
		app-containers/docker
	use git && optfeature "git vcs integration" dev-vcs/git
	use mercurial && optfeature "mercurial vcs integration" dev-vcs/mercurial
	use meson && optfeature "meson buildsystem support" dev-util/meson
	use nim && optfeature "nim language support" dev-lang/nim
	use qbs && optfeature "QBS buildsystem support" dev-util/qbs
	use silversearcher && optfeature "code searching with silversearcher" \
		sys-apps/the_silver_searcher
	use subversion && optfeature "subversion vcs integration" dev-vcs/subversion
	use valgrind && optfeature "valgrind code analysis" dev-util/valgrind
}
