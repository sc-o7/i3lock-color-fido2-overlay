# i3lock-color-fido2 overlay

A Gentoo ebuild repository ("overlay") providing
`x11-misc/i3lock-color`: a fork of
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

### Package name

This overlay deliberately uses the **same package name** as the ::guru package,
`x11-misc/i3lock-color`, rather than a separate `i3lock-color-fido2`. A separate
name would be blocked against `x11-misc/i3lock-color` (both install
`/usr/bin/i3lock`), and that block is unsatisfiable for anyone with a reverse
dependency such as `x11-misc/betterlockscreen`, which requires
`>=x11-misc/i3lock-color-2.13.3`.

Sharing the name means Portage sees the fork as a higher version of the same
package: it satisfies reverse dependencies, and `emerge -uDN @world` upgrades to
it automatically.

Two ebuilds are provided:

| Version | What it builds | Keywords |
| --- | --- | --- |
| `2.13.5_p1` | The tagged release tarball. Use this. | `~amd64` |
| `9999` | The tip of the `fido2-or-password` branch. | none (live) |

The released version needs `~amd64` accepted, which most users already have via
`ACCEPT_KEYWORDS`. If not:

```bash
echo 'x11-misc/i3lock-color ~amd64' \
    | doas tee -a /etc/portage/package.accept_keywords/i3lock-color-fido2
```

Live ebuilds must carry empty `KEYWORDS`
([devmanual](https://devmanual.gentoo.org/ebuild-writing/functions/src_unpack/vcs-sources/index.html)),
so `9999` is opted into separately and is not a substitute for keywording:

```bash
echo '=x11-misc/i3lock-color-9999 **' \
    | doas tee -a /etc/portage/package.accept_keywords/i3lock-color-fido2
```

Then install it. Because it shares the ::guru package name, this is an ordinary
upgrade and no unmerge is needed:

```bash
doas emerge -av x11-misc/i3lock-color
```

You should see Portage pick it from this overlay:

```
[ebuild     U  ] x11-misc/i3lock-color-2.13.5_p1::i3lock-color-fido2 [2.13.5::guru]
```

It still blocks `x11-misc/i3lock` (the non-color original), since both install
`/usr/bin/i3lock`. Unmerge that first if you have it.

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

## Staying on the fork

Portage picks the highest version regardless of repository. The fork is
`2.13.5_p1`, which outranks ::guru's `2.13.5`, so it wins today. If ::guru
publishes `2.13.6`, that would outrank the fork and `emerge -uDN @world` would
silently move you back to upstream, losing FIDO2 support.

To prevent that, mask the package in ::guru so only this overlay can provide it:

```bash
doas mkdir -p /etc/portage/package.mask
echo 'x11-misc/i3lock-color::guru' \
    | doas tee /etc/portage/package.mask/i3lock-color-upstream
```

Verify with:

```bash
emerge --pretend --update x11-misc/i3lock-color
```

Alternatively, watch for upstream releases and rebase the fork onto them,
bumping to e.g. `2.13.6_p1`.

## Updating

Live ebuilds are not upgraded by `emerge -u`. Refresh with:

```bash
doas emaint sync -r i3lock-color-fido2
doas emerge -uav x11-misc/i3lock-color   # released version
doas emerge @live-rebuild                      # only if you installed 9999
```

## Uninstalling

Going back to upstream is a downgrade, not an unmerge. Remove any pin, drop the
repository, and let Portage resolve ::guru again:

```bash
doas rm -f /etc/portage/package.mask/i3lock-color-upstream
doas eselect repository remove -f i3lock-color-fido2
doas emerge -av --oneshot '<x11-misc/i3lock-color-2.13.5_p1'
```

## License

The ebuilds are distributed under the GPL-2, matching Gentoo convention. The
packaged software keeps its own license (BSD).
