# i3lock-color-fido2 overlay

A Gentoo ebuild repository for
[i3lock-color-fido2](https://github.com/sc-o7/i3lock-color-fido2): a fork of
[i3lock-color](https://github.com/Raymo111/i3lock-color) adding the opt-in
`--fido2-or-password` option, so the screen unlocks with a FIDO2 key or the
password, whichever succeeds first.

This is a personal overlay, **not** affiliated with or reviewed by Gentoo, and
deliberately not submitted to
[GURU](https://wiki.gentoo.org/wiki/Project:GURU): GURU expects packages to have
their own upstream rather than fork one it already ships, and asks that packages
be removed once they land elsewhere. Use at your own risk.

## Package name

The package is `x11-misc/i3lock-color`, the **same name** ::guru uses, not a
separate `i3lock-color-fido2`. A separate name would have to block
`x11-misc/i3lock-color` since both install `/usr/bin/i3lock`, and that block is
unsatisfiable for anyone with a reverse dependency such as
`x11-misc/betterlockscreen`, which requires `>=x11-misc/i3lock-color-2.13.3`.

Sharing the name means Portage treats the fork as a higher version of the same
package: reverse dependencies are satisfied and `emerge -uDN @world` picks it up.

| Version | Builds | Keywords |
| --- | --- | --- |
| `2.13.5_p1` | The tagged release tarball. Use this. | `~amd64` |
| `9999` | Tip of the `fido2-or-password` branch. | none (live) |

## Installing

```bash
doas eselect repository add i3lock-color-fido2 git \
    https://github.com/sc-o7/i3lock-color-fido2-overlay.git
doas emaint sync -r i3lock-color-fido2
```

Without `app-eselect/eselect-repository`, add the repository by hand:

```bash
doas tee /etc/portage/repos.conf/i3lock-color-fido2.conf <<'EOF'
[i3lock-color-fido2]
location = /var/db/repos/i3lock-color-fido2
sync-type = git
sync-uri = https://github.com/sc-o7/i3lock-color-fido2-overlay.git
masters = gentoo
auto-sync = yes
EOF
doas emaint sync -r i3lock-color-fido2
```

Accept `~amd64` if you do not already:

```bash
echo 'x11-misc/i3lock-color ~amd64' \
    | doas tee -a /etc/portage/package.accept_keywords/i3lock-color-fido2
```

Live ebuilds must carry empty `KEYWORDS`
([devmanual](https://devmanual.gentoo.org/ebuild-writing/functions/src_unpack/vcs-sources/index.html)),
so `9999` is opted into separately:

```bash
echo '=x11-misc/i3lock-color-9999 **' \
    | doas tee -a /etc/portage/package.accept_keywords/i3lock-color-fido2
```

Then install. Because it shares the ::guru package name this is an ordinary
upgrade, with no unmerge needed:

```bash
doas emerge -av x11-misc/i3lock-color
```

Portage should pick it from this overlay:

```
[ebuild     U  ] x11-misc/i3lock-color-2.13.5_p1::i3lock-color-fido2 [2.13.5::guru]
```

It still blocks `x11-misc/i3lock` (the non-color original), which also installs
`/usr/bin/i3lock`. Unmerge that first if present.

## Configuring FIDO2

The package does **not** create `/etc/pam.d/i3lock-fido2`: installing a package
must not silently add an authentication path to your system. Until that file
exists, `--fido2-or-password` fails closed and password authentication is
unaffected.

1. Install a FIDO2-capable PAM module, for example `sys-auth/pam_u2f`.
2. Enroll the authenticator:
   ```bash
   mkdir -p ~/.config/i3lock
   pamu2fcfg > ~/.config/i3lock/u2f_keys
   chmod 600 ~/.config/i3lock/u2f_keys
   ```
3. Create `/etc/pam.d/i3lock-fido2`, adapting the example installed at
   `/usr/share/doc/i3lock-color-2.13.5_p1/i3lock-fido2.example.bz2`:
   ```
   auth required pam_u2f.so authfile=/home/USER/.config/i3lock/u2f_keys
   ```
   Keep this service isolated from the password stack and from `pam_faillock`.
4. Lock with `i3lock --fido2-or-password`.

## Staying on the fork

Portage picks the highest version regardless of repository. The fork is
`2.13.5_p1`, which outranks ::guru's `2.13.5`. But if ::guru publishes `2.13.6`
that would outrank the fork, and `emerge -uDN @world` would silently move you
back to upstream, losing FIDO2 support.

To prevent that, mask the ::guru package so only this overlay provides it:

```bash
doas mkdir -p /etc/portage/package.mask
echo 'x11-misc/i3lock-color::guru' \
    | doas tee /etc/portage/package.mask/i3lock-color-upstream
```

Verify with `emerge --pretend --update x11-misc/i3lock-color`. Alternatively,
watch for upstream releases and rebase the fork onto them.

## Updating

```bash
doas emaint sync -r i3lock-color-fido2
doas emerge -uav x11-misc/i3lock-color   # released version
doas emerge @live-rebuild                # only if you installed 9999
```

## Uninstalling

Going back to upstream is a downgrade, not an unmerge. Remove the pin, drop the
repository, and let Portage resolve ::guru again:

```bash
doas rm -f /etc/portage/package.mask/i3lock-color-upstream
doas eselect repository remove -f i3lock-color-fido2
doas emerge -av --oneshot '<x11-misc/i3lock-color-2.13.5_p1'
```

## License

The ebuilds are GPL-2, matching Gentoo convention. The packaged software keeps
its own license (BSD).
