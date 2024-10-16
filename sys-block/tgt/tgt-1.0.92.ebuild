# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit toolchain-funcs systemd

DESCRIPTION="Linux SCSI target framework (tgt)"
HOMEPAGE="https://github.com/fujita/tgt"
SRC_URI="https://github.com/fujita/tgt/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm arm64 ~hppa ~loong ~ppc ppc64 ~riscv ~sparc x86"
IUSE="infiniband rbd selinux"

DEPEND="
	app-text/docbook-xsl-stylesheets
	dev-libs/libxslt
	dev-perl/Config-General
	rbd? ( sys-cluster/ceph )
	infiniband? ( sys-cluster/rdma-core )
"
RDEPEND="
	${DEPEND}
	dev-libs/libaio
	sys-apps/sg3_utils
	selinux? ( sec-policy/selinux-tgtd )
"

pkg_setup() {
	tc-export CC
}

src_prepare() {
	default
	sed -i -e 's:\($(CC)\) $^:\1 $(LDFLAGS) $^:' usr/Makefile || die
	# make sure xml docs are generated before trying to install them
	sed -i -e "s@install: @& all @g" doc/Makefile || die
	sed -i -e 's|-Werror||g' usr/Makefile || die
}

src_compile() {
	local myconf
	use infiniband && myconf="${myconf} ISCSI_RDMA=1"
	use rbd && myconf="${myconf} CEPH_RBD=1"

	emake -C usr/ KERNELSRC="${KERNEL_DIR}" ISCSI=1 ${myconf}
	emake -C doc
}

src_install() {
	emake  install-programs install-scripts install-doc DESTDIR="${D}" docdir=/usr/share/doc/${PF}
	newinitd "${FILESDIR}"/tgtd.initd-new tgtd
	newconfd "${FILESDIR}"/tgtd.confd-new tgtd
	systemd_dounit "${S}"/scripts/tgtd.service
	dodir /etc/tgt
	keepdir /etc/tgt
}
