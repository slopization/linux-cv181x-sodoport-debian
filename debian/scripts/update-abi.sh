#!/bin/sh
# Sync the ABI embedded in package names and maintainer-script filenames with
# the kernel source version. debian/rules derives KERNEL_ABI the same way, so
# running this keeps the static packaging metadata in step with the tree.
#
#   debian/scripts/update-abi.sh /path/to/linux
set -eu

linux=${1:-}
if [ -z "$linux" ]; then
	echo "usage: $0 /path/to/linux" >&2
	exit 1
fi

ver=$(sed -n 's/^VERSION = //p' "$linux/Makefile" | head -1)
pl=$(sed -n 's/^PATCHLEVEL = //p' "$linux/Makefile" | head -1)
sl=$(sed -n 's/^SUBLEVEL = //p' "$linux/Makefile" | head -1)
new=$(printf '%s.%s.%s' "$ver" "$pl" "$sl")

dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
old=$(sed -n 's/^Package: linux-image-\([0-9][0-9.]*\)-cv181x-sodoport$/\1/p' \
	"$dir/control" | head -1)
[ -n "$old" ] || { echo "cannot find the current ABI in debian/control" >&2; exit 1; }

if [ "$old" = "$new" ]; then
	echo "ABI already $new, nothing to do"
	exit 0
fi

echo "ABI: $old -> $new"
sed -i "s/$old/$new/g" "$dir/control"
for f in "$dir"/*"$old"*; do
	[ -e "$f" ] || continue
	mv "$f" "${f%%$old*}${new}${f#*$old}"
	echo "  renamed $(basename "$f")"
done
