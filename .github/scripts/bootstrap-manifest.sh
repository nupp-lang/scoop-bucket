#!/usr/bin/env bash

set -euo pipefail

manifest="bucket/nupp.json"
repository="${NUPP_RELEASE_REPOSITORY:-nupp-lang/nupp}"
release_directory="${NUPP_RELEASE_DIRECTORY:-}"
tag="${NUPP_RELEASE_TAG:-}"

if [[ -f "$manifest" ]]; then
  echo "Nupp manifest already exists; Excavator will maintain it"
  exit 0
fi

if [[ -z "$tag" ]]; then
  response=$(mktemp)
  status=$(curl --silent --show-error --location \
    --output "$response" --write-out '%{http_code}' \
    --header "Accept: application/vnd.github+json" \
    --header "Authorization: Bearer $GITHUB_TOKEN" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$repository/releases/latest")
  case "$status" in
    200)
      tag=$(jq -r .tag_name "$response")
      ;;
    404)
      echo "Nupp has no published release yet"
      exit 0
      ;;
    *)
      cat "$response" >&2
      echo "GitHub returned HTTP $status while finding the latest Nupp release" >&2
      exit 1
      ;;
  esac
fi

if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Nupp release tag is not a version: $tag" >&2
  exit 1
fi

version="${tag#v}"
if [[ -z "$release_directory" ]]; then
  release_directory=$(mktemp -d)
  gh release download "$tag" --repo "$repository" \
    --pattern 'nupp-windows-x86_64.zip' \
    --dir "$release_directory"
fi

archive="$release_directory/nupp-windows-x86_64.zip"
test -f "$archive"
unzip -Z1 "$archive" | grep -Eq '^(\./)?nupp\.exe$'

if command -v sha256sum >/dev/null 2>&1; then
  archive_sha=$(sha256sum "$archive" | awk '{print $1}')
else
  archive_sha=$(shasum -a 256 "$archive" | awk '{print $1}')
fi

mkdir -p bucket
cat > "$manifest" <<MANIFEST
{
    "version": "$version",
    "description": "Typed programming language for LuaJIT with an optimizing compiler",
    "homepage": "https://github.com/$repository",
    "license": "Unknown",
    "url": "https://github.com/$repository/releases/download/$tag/nupp-windows-x86_64.zip",
    "hash": "$archive_sha",
    "bin": "nupp.exe",
    "checkver": "github",
    "autoupdate": {
        "url": "https://github.com/$repository/releases/download/v\$version/nupp-windows-x86_64.zip"
    }
}
MANIFEST

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "created=true" >> "$GITHUB_OUTPUT"
fi
echo "Prepared $manifest for Nupp $version"
