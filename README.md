# Nupp Scoop bucket

This bucket distributes the prebuilt Windows x86-64 release of
[Nupp](https://nupp.org), including its bundled native compiler pack and
third-party notices.

Once the first Nupp release is published, install it with:

```powershell
scoop bucket add nupp https://github.com/nupp-lang/scoop-bucket
scoop install nupp
```

Upgrade to a later release with:

```powershell
scoop update
scoop update nupp
```

## Updates

The [Excavator](.github/workflows/excavator.yml) workflow checks
[Nupp releases](https://github.com/nupp-lang/nupp/releases) every six hours.
The first published release creates `bucket/nupp.json`; Scoop's standard
`checkver` and `autoupdate` support maintain it after that. Before the first
release exists, the workflow exits successfully without creating an
uninstallable placeholder manifest.
