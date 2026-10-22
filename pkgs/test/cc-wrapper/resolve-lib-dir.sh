# Unit tests for resolveLibDir, which ld-wrapper uses to decide which -L
# directories go into the rpath.
#
# Usage: resolve-lib-dir.sh <path to a wrapper's nix-support/utils.bash>
set -eu -o pipefail

# shellcheck source=/dev/null
source "$1"

root=$(mktemp -d)
root=$(cd "$root" && pwd -P)
cd "$root"

# A fake store, and directories outside it that lead into it.
S=$root/store
mkdir -p "$S/a/lib" "$S/b" out/real/x out/sub
ln -s "$S/a" "$S/link"
ln -s ../a/lib "$S/b/sub"
ln -s "$S/a/lib" out/abs
ln -s ../abs out/sub/rel
ln -s "$S/a" out/dirlink
ln -s "$root/out/real/x" out/p
ln -s "$S/a/lib" out/real/store-link
ln -s ../store-link out/real/x/rel
ln -s "$S" out/storelink
ln -s loop2 out/loop1
ln -s loop1 out/loop2
# A store that is itself reached through a symlink.
mkdir -p real-nix/store/a/lib
ln -s real-nix nixlink

declare -i failures=0

# check <expected result, or FAIL> <path> [store]
check() {
    local expected=$1 path=$2 actual
    resolvedLibDir=
    if NIX_STORE=${3:-$S} resolveLibDir "$path"; then
        actual=$resolvedLibDir
    else
        actual=FAIL
    fi
    if [[ "$actual" != "$expected" ]]; then
        echo "resolveLibDir $path: expected $expected, got $actual" >&2
        failures+=1
    fi
}

# Store paths: symlinks in the store are kept (issue #454199), without
# running any command (issue #545973).
PATH=/no-such-dir check "$S/a/lib" "$S/a/lib"
PATH=/no-such-dir check "$S/link/lib" "$S/link/lib"
PATH=/no-such-dir check "$S/link/lib" "$S/link/./lib"
check "$S/a/lib" "$S//a/lib/"

# `..` after a symlink steps out of its target, even in the store.
check "$S/a/lib" "$S/b/sub/../lib"

# Symlinks outside the store are resolved.
check "$S/a/lib" out/abs
check "$S/a/lib" "$root/out/sub/rel"
check "$S/a/lib" "$root/out/dirlink/lib"
check "$S/a/lib" "$root/out/p/rel"
check "$S/a/lib" "$root/out/storelink/a/lib"
check "$root/out/real/x" "$root/out/p"

# The store directory and its ancestors are not resolved.
check "$root/nixlink/store/a/lib" "$root/nixlink/store/a/lib" "$root/nixlink/store"
check "$root/nixlink/store/a/lib" "$root/nixlink/store/./a/lib" "$root/nixlink/store"

# Directories that cannot be reached.
check FAIL "$root/out/loop1"
check FAIL "$root/out/missing/../abs"

if (( failures > 0 )); then
    exit 1
fi
