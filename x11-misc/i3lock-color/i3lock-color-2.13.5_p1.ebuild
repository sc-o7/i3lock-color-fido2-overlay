# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools out-of-source shell-completion

DESCRIPTION="i3lock-color fork with opt-in FIDO2-or-password authentication"
HOMEPAGE="https://github.com/sc-o7/i3lock-color-fido2"
SRC_URI="https://github.com/sc-o7/i3lock-color-fido2/archive/refs/tags/${PV}.tar.gz
	-> ${P}.tar.gz"
# GitHub names the archive directory after the repository, which is
# i3lock-color-fido2, while PN is i3lock-color so the package can replace the
# ::guru one. They differ, so S must be spelled out.
MY_PN="i3lock-color-fido2"
S="${WORKDIR}/${MY_PN}-${PV}"

LICENSE="BSD"
SLOT="0"
# Only ~amd64 is keyworded because that is the only arch this has been
# built and used on. Upstream i3lock-color also supports ~arm ~arm64 ~x86;
# add them here once someone has actually tested them.
KEYWORDS="~amd64"

# --fido2-or-password needs no extra libraries. It reaches FIDO2 through a
# second PAM service, so the requirement is a FIDO2-capable PAM module at
# runtime, not a link-time dependency. There is deliberately no USE flag: the
# feature is opt-in on the command line, so building it in costs nothing and a
# flag would only produce two binaries that behave identically until the option
# is passed. See PG 0001 on optional runtime dependencies.
DEPEND="
	dev-libs/libev
	media-libs/fontconfig
	media-libs/libjpeg-turbo:=
	sys-libs/pam
	x11-libs/cairo[X]
	x11-libs/libxcb:=
	x11-libs/libxkbcommon[X]
	x11-libs/xcb-util
	x11-libs/xcb-util-image
	x11-libs/xcb-util-xrm
"
RDEPEND="
	${DEPEND}
	!!x11-misc/i3lock
"
BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}/${PN}-cleanup-cflags.patch"
	"${FILESDIR}/${PN}-disable-automagic.patch"
)

src_prepare() {
	default
	eautoreconf
}

src_install() {
	out-of-source_src_install
	newbashcomp i3lock-bash i3lock
	newzshcomp i3lock-zsh _i3lock
	dodoc pam/i3lock-fido2.example
}

pkg_postinst() {
	elog "This is the FIDO2 fork of i3lock-color, installed under the same"
	elog "package name so that it satisfies dependencies such as"
	elog "x11-misc/betterlockscreen. Portage prefers it over ::guru only while"
	elog "its version sorts higher; pin it with a repository entry in"
	elog "/etc/portage/package.mask or package.accept_keywords if ::guru"
	elog "publishes a newer version. See the overlay README."
	elog
	elog "Password-only behaviour is unchanged. To use FIDO2:"
	elog
	elog "  1. Install a FIDO2-capable PAM module, e.g. sys-auth/pam_u2f."
	elog "  2. Enroll your authenticator (pamu2fcfg > ~/.config/i3lock/u2f_keys)."
	elog "  3. Create /etc/pam.d/i3lock-fido2. An example is installed at"
	elog "     ${EROOT}/usr/share/doc/${PF}/i3lock-fido2.example.bz2"
	elog "  4. Run: i3lock --fido2-or-password"
	elog
	elog "The PAM service is NOT installed automatically: a package must not"
	elog "silently add an authentication path to your system. Without it,"
	elog "--fido2-or-password fails closed and password auth still works."
}
