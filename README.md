# i3lock-color-fido2 overlay

A Gentoo ebuild repository ("overlay") providing
`x11-misc/i3lock-color-fido2`: a fork of
[i3lock-color](https://github.com/Raymo111/i3lock-color) that adds the opt-in
`--fido2-or-password` option, so the screen can be unlocked with a FIDO2 key or
the password, whichever succeeds first.

Source for the fork itself: <https://github.com/YOUR-USERNAME/i3lock-color-fido2>

## Relationship to Gentoo

This is a personal overlay. It is **not** affiliated with, endorsed by, or
reviewed by Gentoo, and it is deliberately **not** submitted to
[GURU](https://wiki.gentoo.org/wiki/Project:GURU):

- GURU expects packages to have their own upstream. This package's upstream is a
  fork of `x11-misc/i3lock-color`, which GURU already ships, so adding it there
  would duplicate and confuse an existing package.
- The fork is meant to be temporary. If the feature is merged upstream, this
  overlay and the fork are archived, and users go back to
  `x11-misc/i3lock-color`. GURU asks that packages be removed once they land
  elsewhere, so adding a package intended for deletion is poor practice.

Use it at your own risk, as with any third-party overlay.

## Installing

```bash
# app-eselect/eselect-repository is required for this method
doas eselect repository add i3lock-color-fido2 git \
    https://github.com/YOUR-USERNAME/i3lock-color-fido2-overlay.git
doas emaint sync -r i3lock-color-fido2
```

Two ebuilds are provided:

| Version | What it builds | Keywords |
| --- | --- | --- |
| `2.13.5_p1` | The tagged release tarball. Use this. | `~amd64` |
| `9999` | The tip of the `fido2-or-password` branch. | none (live) |

The released version needs `~amd64` accepted, which most users already have via
`ACCEPT_KEYWORDS`. If not:

```bash
echo 'x11-misc/i3lock-color-fido2 ~amd64' \
    | doas tee -a /etc/portage/package.accept_keywords/i3lock-color-fido2
```

Live ebuilds must carry empty `KEYWORDS`
([devmanual](https://devmanual.gentoo.org/ebuild-writing/functions/src_unpack/vcs-sources/index.html)),
so `9999` is opted into separately and is not a substitute for keywording:

```bash
echo '=x11-misc/i3lock-color-fido2-9999 **' \
    | doas tee -a /etc/portage/package.accept_keywords/i3lock-color-fido2
```

This package installs `/usr/bin/i3lock` and therefore blocks
`x11-misc/i3lock` and `x11-misc/i3lock-color`. Remove whichever you have:

```bash
doas emerge --deselect x11-misc/i3lock-color
doas emerge -C x11-misc/i3lock-color
doas emerge -av x11-misc/i3lock-color-fido2
```

### Without eselect-repository

Add the repository manually instead:

```bash
doas tee /etc/portage/repos.conf/i3lock-color-fido2.conf <<'EOF'
[i3lock-color-fido2]
location = /var/db/repos/i3lock-color-fido2
sync-type = git
sync-uri = https://github.com/YOUR-USERNAME/i3lock-color-fido2-overlay.git
masters = gentoo
auto-sync = yes
EOF
doas emaint sync -r i3lock-color-fido2
```

## Configuring FIDO2

The package does **not** create `/etc/pam.d/i3lock-fido2`. Installing a package
must not silently add an authentication path to your system, so this step is
left to you. Until it exists, `--fido2-or-password` fails closed and password
authentication is unaffected.

1. Install a FIDO2-capable PAM module, for example `sys-auth/pam_u2f`.
2. Enroll the authenticator:
   ```bash
   mkdir -p ~/.config/i3lock
   pamu2fcfg > ~/.config/i3lock/u2f_keys
   chmod 600 ~/.config/i3lock/u2f_keys
   ```
3. Create `/etc/pam.d/i3lock-fido2`, adapting the example installed at
   `/usr/share/doc/i3lock-color-fido2-*/i3lock-fido2.example.bz2`:
   ```
   auth required pam_u2f.so authfile=/home/USER/.config/i3lock/u2f_keys cue
   ```
   Keep this service isolated from the password stack and from `pam_faillock`.
4. Lock with `i3lock --fido2-or-password`.

## Updating

Live ebuilds are not upgraded by `emerge -u`. Refresh with:

```bash
doas emaint sync -r i3lock-color-fido2
doas emerge -uav x11-misc/i3lock-color-fido2   # released version
doas emerge @live-rebuild                      # only if you installed 9999
```

## Uninstalling

```bash
doas emerge -C x11-misc/i3lock-color-fido2
doas eselect repository remove -f i3lock-color-fido2
doas emerge -av x11-misc/i3lock-color   # back to upstream, from ::guru
```

## License

The ebuilds are distributed under the GPL-2, matching Gentoo convention. The
packaged software keeps its own license (BSD).
