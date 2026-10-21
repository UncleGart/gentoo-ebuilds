# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 linux-info systemd

DESCRIPTION="Proton VPN system daemon providing per-application split tunneling"
HOMEPAGE="https://github.com/ProtonVPN/proton-vpn-daemon"
SRC_URI="https://github.com/ProtonVPN/proton-vpn-daemon/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
# Tests need root, a live BPF-capable kernel and the system bus.
RESTRICT="test"

RDEPEND="
	$(python_gen_cond_dep '
		dev-python/dbus-fast[${PYTHON_USEDEP}]
		dev-python/packaging[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/python-systemd[${PYTHON_USEDEP}]
		>=dev-python/proton-vpn-api-core-5.3.1[${PYTHON_USEDEP}]
		dev-util/bcc[python,${PYTHON_USEDEP}]
	')
	sys-apps/dbus
	sys-apps/systemd
"

# The process monitor attaches kprobes/tracepoints; the socket monitor
# attaches a BPF_PROG_TYPE_CGROUP_SOCK program to /sys/fs/cgroup/user.slice.
CONFIG_CHECK="
	~BPF ~BPF_SYSCALL ~BPF_EVENTS ~KPROBES ~KPROBE_EVENTS
	~TRACEPOINTS ~PERF_EVENTS ~CGROUPS ~CGROUP_BPF
"

pkg_setup() {
	linux-info_pkg_setup
	python-single-r1_pkg_setup
}

src_prepare() {
	distutils-r1_src_prepare

	sed -i "/--cov/d" setup.cfg || die

	cd rpmbuild/SOURCES || die
	# Upstream's D-Bus activation file names a systemd unit that does not
	# exist (proton.VPN.service); point it at the unit that is installed.
	sed -i 's|^SystemdService=.*|SystemdService=me.proton.vpn.split_tunneling.service|' \
		dbus.service || die
	# Run the daemon with the Python implementation it was installed for.
	sed -i "s|^ExecStart=.*|ExecStart=/usr/bin/${EPYTHON} -m proton.vpn.daemon|" \
		systemd.service || die
}

src_install() {
	distutils-r1_src_install

	insinto /usr/share/dbus-1/system.d
	# Upstream lets any local user own the bus name; ours restricts it to root.
	doins "${FILESDIR}"/me.proton.vpn.split_tunneling.conf
	insinto /usr/share/dbus-1/system-services
	newins rpmbuild/SOURCES/dbus.service me.proton.vpn.split_tunneling.service
	systemd_newunit rpmbuild/SOURCES/systemd.service me.proton.vpn.split_tunneling.service
}

pkg_postinst() {
	elog "Split tunneling only works while this daemon is running: the app checks"
	elog "for the bus name already being present and never D-Bus-activates it."
	elog "Enable and start it with:"
	elog "  systemctl enable --now me.proton.vpn.split_tunneling.service"
	elog "then restart the Proton VPN app."
	elog
	elog "BCC compiles the daemon's eBPF program at runtime and needs the"
	elog "headers of the running kernel (/lib/modules/\$(uname -r)/build, or"
	elog "CONFIG_IKHEADERS=y)."
}
