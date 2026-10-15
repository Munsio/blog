#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [-n|--dry-run] [-f|--force] [slug...]

Syncs post bundles (<slug>/index.md + media) from the Obsidian vault into
content/en/posts/<slug>/, converting Obsidian embeds and wikilinks to Markdown.
Without slugs, every bundle in the vault posts folder is synced.

  -n, --dry-run  show what would change without writing anything
  -f, --force    overwrite an existing post that wasn't synced from the vault before

Env:
  OBSIDIAN_POSTS_DIR  vault posts folder
                      (default: ~/Documents/obsidian/Brain/01 Projects/Blog/Posts)
EOF
}

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
src_root=${OBSIDIAN_POSTS_DIR:-$HOME/Documents/obsidian/Brain/01 Projects/Blog/Posts}
dst_root=$repo/content/en/posts
manifest=$repo/.obsidian-synced

dry_run=0
force=0
slugs=()
while (($#)); do
  case $1 in
    -n | --dry-run) dry_run=1 ;;
    -f | --force) force=1 ;;
    -h | --help) usage; exit 0 ;;
    -*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) slugs+=("$1") ;;
  esac
  shift
done

[[ -d $src_root ]] || { echo "vault posts folder not found: $src_root" >&2; exit 1; }

if ((${#slugs[@]} == 0)); then
  for dir in "$src_root"/*/; do
    [[ -f $dir/index.md ]] && slugs+=("$(basename "$dir")")
  done
fi
((${#slugs[@]})) || { echo "no post bundles found in $src_root"; exit 0; }

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Converts Obsidian syntax outside code fences; warnings go to stderr.
convert() {
  SLUG=$1 BUNDLE=$2 perl -ne '
    our $fence;
    sub warnf { printf STDERR "  warn: %s: %s\n", $ENV{SLUG}, shift }
    sub embed {
      my ($target, $opt) = @_;
      unless ($target =~ /\.(?:png|jpe?g|gif|webp|svg|avif)$/i) {
        warnf("note embed ![[$target]] has no blog equivalent, left as-is");
        return "![[$target" . (defined $opt ? "|$opt" : "") . "]]";
      }
      warnf("missing image $target in bundle") unless -e "$ENV{BUNDLE}/$target";
      my $alt = (defined $opt && $opt !~ /^\d+(?:x\d+)?$/) ? $opt : "";
      if ($alt eq "") {
        ($alt = $target) =~ s{.*/}{};
        $alt =~ s/\.[^.]+$//;
        $alt =~ tr/-_/  /;
      }
      my $dest = $target =~ /[\s()]/ ? "<$target>" : $target;
      return "![$alt]($dest)";
    }
    if (/^\s*(?:```|~~~)/) { $fence = !$fence; print; next }
    unless ($fence) {
      s/%%.*?%%//g;
      s/!\[\[([^\]|]+?)(?:\|([^\]]*))?\]\]/embed($1, $2)/ge;
      s{(?<!!)\[\[([^\]|#]+)(?:#[^\]|]*)?(?:\|([^\]]*))?\]\]}{
        warnf("wikilink [[$1]] converted to plain text");
        defined $2 ? $2 : $1
      }ge;
    }
    print;
  ' "$2/index.md"
}

synced=0
for slug in "${slugs[@]}"; do
  src=$src_root/$slug
  dst=$dst_root/$slug

  if [[ ! $slug =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    echo "skip $slug: folder name must be a lowercase-dashed slug (it becomes the URL)" >&2
    continue
  fi
  if [[ ! -f $src/index.md ]]; then
    echo "skip $slug: no index.md in $src" >&2
    continue
  fi
  if [[ -d $dst ]] && ! grep -qxF "$slug" "$manifest" 2>/dev/null && ((!force)); then
    echo "skip $slug: content/en/posts/$slug exists and wasn't synced from the vault (use --force)" >&2
    continue
  fi

  echo "sync $slug"
  convert "$slug" "$src" >"$tmp"

  rsync_opts=(-a --delete --exclude='.*' --exclude='*.md')
  if ((dry_run)); then
    rsync "${rsync_opts[@]}" -n -i "$src/" "$dst/" | sed 's/^/  /'
    if [[ -f $dst/index.md ]]; then
      diff -u --label "posts/$slug/index.md" --label "vault/$slug/index.md" "$dst/index.md" "$tmp" | sed 's/^/  /' || true
    else
      echo "  new post"
    fi
    continue
  fi

  mkdir -p "$dst"
  rsync "${rsync_opts[@]}" "$src/" "$dst/"
  cp "$tmp" "$dst/index.md"
  if ! grep -qxF "$slug" "$manifest" 2>/dev/null; then
    echo "$slug" >>"$manifest"
    sort -o "$manifest" "$manifest"
  fi
  synced=$((synced + 1))
done

if ((!dry_run && synced)); then
  echo "synced $synced post(s); preview with: hugo server -D"
fi
