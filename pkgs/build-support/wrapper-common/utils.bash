# Accumulate suffixes for taking in the right input parameters with the `mangle*`
# functions below. See setup-hook for details.
accumulateRoles() {
    declare -ga role_suffixes=()
    if [ "${NIX_@wrapperName@_TARGET_BUILD_@suffixSalt@:-}" ]; then
        role_suffixes+=('_FOR_BUILD')
    fi
    if [ "${NIX_@wrapperName@_TARGET_HOST_@suffixSalt@:-}" ]; then
        role_suffixes+=('')
    fi
    if [ "${NIX_@wrapperName@_TARGET_TARGET_@suffixSalt@:-}" ]; then
        role_suffixes+=('_FOR_TARGET')
    fi
}

mangleVarListGeneric() {
    local sep="$1"
    shift
    local var="$1"
    shift
    local -a role_suffixes=("$@")

    local outputVar="${var}_@suffixSalt@"
    declare -gx "$outputVar"+=''
    # For each role we serve, we accumulate the input parameters into our own
    # cc-wrapper-derivation-specific environment variables.
    for suffix in "${role_suffixes[@]}"; do
        local inputVar="${var}${suffix}"
        if [ -v "$inputVar" ]; then
            export "${outputVar}+=${!outputVar:+$sep}${!inputVar}"
        fi
    done
}

mangleVarList() {
    mangleVarListGeneric " " "$@"
}

mangleVarBool() {
    local var="$1"
    shift
    local -a role_suffixes=("$@")

    local outputVar="${var}_@suffixSalt@"
    declare -gxi "${outputVar}+=0"
    for suffix in "${role_suffixes[@]}"; do
        local inputVar="${var}${suffix}"
        if [ -v "$inputVar" ]; then
            # "1" in the end makes `let` return success error code when
            # expression itself evaluates to zero.
            # We don't use `|| true` because that would silence actual
            # syntax errors from bad variable values.
            let "${outputVar} |= ${!inputVar:-0}" "1"
        fi
    done
}

# Combine a singular value from all roles. If multiple roles are being served,
# and the value differs in these roles then the request is impossible to
# satisfy and we abort immediately.
mangleVarSingle() {
    local var="$1"
    shift
    local -a role_suffixes=("$@")

    local outputVar="${var}_@suffixSalt@"
    for suffix in "${role_suffixes[@]}"; do
        local inputVar="${var}${suffix}"
        if [ -v "$inputVar" ]; then
            if [ -v "$outputVar" ]; then
                if [ "${!outputVar}" != "${!inputVar}" ]; then
                    {
                        echo "Multiple conflicting values defined for $outputVar"
                        echo "Existing value is ${!outputVar}"
                        echo "Attempting to set to ${!inputVar} via $inputVar"
                    } >&2

                    exit 1
                fi
            else
                declare -gx ${outputVar}="${!inputVar}"
            fi
        fi
    done
}

skip() {
    if (( "${NIX_DEBUG:-0}" >= 1 )); then
        echo "skipping impure path $1" >&2
    fi
}

reject() {
    echo "impure path \`$1' used in link" >&2
    exit 1
}


# Checks whether a path is impure.  E.g., `/lib/foo.so' is impure, but
# `/nix/store/.../lib/foo.so' isn't.
badPath() {
    local p=$1

    # Relative paths are okay (since they're presumably relative to
    # the temporary build directory).
    if [ "${p:0:1}" != / ]; then return 1; fi

    # Otherwise, the path should refer to the store or some temporary
    # directory (including the build directory).
    test \
        "$p" != "/dev/null" -a \
        "${p#"${NIX_STORE}"}"     = "$p" -a \
        "${p#"${NIX_BUILD_TOP}"}" = "$p" -a \
        "${p#/tmp}"               = "$p" -a \
        "${p#"${TMP:-/tmp}"}"     = "$p" -a \
        "${p#"${TMPDIR:-/tmp}"}"  = "$p" -a \
        "${p#"${TEMP:-/tmp}"}"    = "$p" -a \
        "${p#"${TEMPDIR:-/tmp}"}" = "$p"
}

# Like `badPath`, but handles paths that may be interpreted relative to
# `$SDKROOT` on Darwin. For example, `-L/usr/lib/swift` is interpreted
# as `-L$SDKROOT/usr/lib/swift` when `$SDKROOT` is set and
# `$SDKROOT/usr/lib/swift` exists.
badPathWithDarwinSdk() {
    path=$1
    if [[ "@darwinMinVersion@" ]]; then
        sdkPath=$SDKROOT/$path
        if [[ -e $sdkPath ]]; then
            path=$sdkPath
        fi
    fi
    badPath "$path"
}

# Resolves the library directory $1 for use in the rpath and stores the
# result in `resolvedLibDir`. Returns 1 if the directory cannot be reached.
#
# Symlinks outside the store are resolved, so that a directory reached
# through them is recognized as being in the store. Symlinks inside the
# store are kept, because resolving them breaks bootstrapping (see issue
# #454199), unless a `..` steps out of one: the kernel resolves `..` after
# a symlink from the symlink's target. The store directory and its
# ancestors are never resolved, as the store may itself be reached through
# a symlink.
resolveLibDir() {
    local path=$1 store=${NIX_STORE:-}
    local resolved='' rest component target
    local -i symlinks=0

    # Fast path: nearly every -L directory is a canonical store path, which
    # stays as it is. ld-wrapper resolves every -L directory on every link,
    # so this must not fork, see issue #545973.
    if [[ "$path" == "$store"/* && "$path" != *//* && "$path" != */./* && "$path" != */../* \
            && "$path" != */. && "$path" != */.. && "$path" != */ ]]; then
        # resolvedLibDir is used by caller
        # shellcheck disable=SC2034
        resolvedLibDir=$path
        return 0
    fi

    if [[ "$path" != /* ]]; then
        path=$PWD/$path
    fi
    rest=${path#/}
    # Walk the path one component at a time, appending to `resolved`.
    while [[ -n "$rest" ]]; do
        component=${rest%%/*}
        if [[ "$rest" == */* ]]; then
            rest=${rest#*/}
        else
            rest=
        fi
        case "$component" in
            '' | .)
                continue
                ;;
            ..)
                if [[ ! -L "$resolved" ]]; then
                    if [[ -n "$resolved" && ! -d "$resolved" ]]; then
                        return 1
                    fi
                    resolved=${resolved%/*}
                    continue
                fi
                # Resolve the symlink below, then step out of its target.
                rest=..${rest:+/$rest}
                ;;
            *)
                resolved=$resolved/$component
                if [[ "$resolved" == "$store"/* || "$store" == "$resolved" || "$store" == "$resolved"/* \
                        || ! -L "$resolved" ]]; then
                    continue
                fi
                ;;
        esac
        # `resolved` is a symlink to resolve: walk its target instead.
        if (( ++symlinks > 40 )); then
            return 1
        fi
        target=$(readlink "$resolved") || return 1
        rest=$target${rest:+/$rest}
        if [[ "$target" == /* ]]; then
            resolved=
        else
            resolved=${resolved%/*}
        fi
    done
    # shellcheck disable=SC2034
    resolvedLibDir=${resolved:-/}
}

expandResponseParams() {
    declare -ga params=("$@")
    local arg
    for arg in "$@"; do
        if [[ "$arg" == @* ]]; then
            # phase separation makes this look useless
            # shellcheck disable=SC2157
            if [ -x "@expandResponseParams@" ]; then
                # params is used by caller
                #shellcheck disable=SC2034
                readarray -d '' params < <("@expandResponseParams@" "$@")
                return 0
            fi
        fi
    done
}

checkLinkType() {
    local arg
    type="dynamic"
    for arg in "$@"; do
        if [[ "$arg" = -static ]]; then
            type="static"
        elif [[ "$arg" = -static-pie ]]; then
            type="static-pie"
        fi
    done
    echo "$type"
}

# When building static-pie executables we cannot have rpath
# set. At least glibc requires rpath to be empty
filterRpathFlags() {
    local linkType=$1 ret i
    shift

    if [[ "$linkType" == "static-pie" ]]; then
        while [[ "$#" -gt 0 ]]; do
            i="$1"; shift 1
            if [[ "$i" == -rpath ]]; then
                # also skip its argument
                shift
            else
                ret+=("$i")
            fi
        done
    else
        ret=("$@")
    fi
    echo "${ret[@]}"
}
