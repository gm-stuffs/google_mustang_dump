#!/vendor/bin/sh
set -euo pipefail
#
# upgrade recovery DBL image for current slot
#

# Log messages to both logcat and the shell
LOG_TAG=init_rdbl

RDBL_SRC="/vendor/firmware/rdbl.img"
RDBL_DST="/dev/block/by-name/rdbl"

HEADER_SIZE_BYTES=4096 # 0x1000 in decimal
# 0x0864 in decimal according to Delegate Header field in
# https://docs.google.com/document/d/1TqvbWB7Mcyk51xcnq7SY0fUfWg4fgeumfDwZJkxoOtM/edit?resourcekey=0--jNpAnVLFKkai4RQc9n7mA&tab=t.0#bookmark=id.xwveawb2okfo
DELEGATE_POLICY_OFFSET=2148
# 0x4 in demical according to SW RollbackInfo filed in
# https://docs.google.com/document/d/1TqvbWB7Mcyk51xcnq7SY0fUfWg4fgeumfDwZJkxoOtM/edit?resourcekey=0--jNpAnVLFKkai4RQc9n7mA&tab=t.0#bookmark=id.l62dsdyy61u6
SW_ROLLBACK_INFO_OFFSET=4 # 0x4 in decimal
VALUE_SIZE_BYTES=4 # 32 bits

log_info() {
    log -p i -t "${LOG_TAG}" "$1"
    echo "$1" >&2
}

log_error() {
    log -p e -t "${LOG_TAG}" "$1"
    echo "$1" >&2
}

# TODO(b/423758817): get the device DBL AR from adb
# Function to extract the 64-bit value from the header
get_antirollback_value() {
    local image_path="$1"
    local offset="$(( $2 ))"
    local size="$(( $3 ))"

    # Check if the image path is readable
    if [[ ! -r "$image_path" ]]; then
        log_error "Cannot read from '$image_path' to extract header value."
        return 1
    fi

    # Read the specific bytes using dd and convert to hex for comparison
    local hex_value
    hex_value=$(dd if="$image_path" bs=1 skip=$offset count=$size status=none 2>/dev/null | xxd -p | tr -d '\n')

    if [[ -n "$hex_value" ]]; then
        printf "%d" "0x${hex_value}"
    else
        return 1
    fi
}

log_info "Starting recovery DBL update check."

# Get SHA1 hash of source recovery DBL image
if [[ ! -r "$RDBL_SRC" ]]; then
    log_error "Source rDBL '$RDBL_SRC' is not readable. Cannot proceed."
    exit 1
fi

RDBL_SRC_SIZE=$(stat -c %s "$RDBL_SRC")
if [[ -z "$RDBL_SRC_SIZE" ]]; then
    log_error "Failed to get size of source rDBL image."
    exit 1
fi

rdbl_src_hash=$(sha1sum -b "$RDBL_SRC" | cut -d ' ' -f 1)

# Get SHA1 hash of destination recovery DBL image
if [[ ! -w "$RDBL_DST" ]]; then
    log_error "Destination rDBL '$RDBL_DST' is not writable. Cannot proceed."
    exit 2
fi
rdbl_dst_hash=$(dd if="$RDBL_DST" bs=1 count="$RDBL_SRC_SIZE" status=none 2>/dev/null | sha1sum -b | cut -d ' ' -f 1)

if [[ "$rdbl_src_hash" == "$rdbl_dst_hash" ]]; then
    log_info "SHA1 hashes match. Recovery DBL is already up to date. No replacement needed."
    exit 0
else
    log_info "SHA1 hashes mismatch detected. Built-in rDBL differs from incoming rDBL."

    # Get the Rollback information for source and destination recovery DBL image
    rdbl_src_ar_dec=$(get_antirollback_value "$RDBL_SRC" $DELEGATE_POLICY_OFFSET+$SW_ROLLBACK_INFO_OFFSET $VALUE_SIZE_BYTES)
    rdbl_dst_ar_dec=$(get_antirollback_value "$RDBL_DST" $DELEGATE_POLICY_OFFSET+$SW_ROLLBACK_INFO_OFFSET $VALUE_SIZE_BYTES)

    if (( rdbl_src_ar_dec < rdbl_dst_ar_dec )); then
        log_info "Skipping update to prevent downgrade."
        exit 0
    else
        log_info "Recovery DBL is being replaced..."

        if dd if="$RDBL_SRC" of="$RDBL_DST" bs=1M conv=fsync; then
            # Re-calculate hash of the destination after writing
            local post_write_rdbl_dst_hash=$(dd if="$RDBL_DST" bs=1 count="$RDBL_SRC_SIZE" status=none 2>/dev/null | sha1sum -b | cut -d ' ' -f 1)
            if [[ -z "$post_write_rdbl_dst_hash" ]]; then
                log_error "Failed to re-extract anti-rollback value from destination after write. Verification incomplete."
                exit 3
            fi

            if [[ "$rdbl_src_hash" == "$post_write_rdbl_dst_hash" ]]; then
                log_info "Verification successful: New rDBL hash matches source."
            else
                log_error "VERIFICATION FAILED! Written rDBL hash does NOT match source."
                exit 4
            fi
        else
            log_error "Failed to write recovery DBL to '$RDBL_DST' during dd operation."
            exit 5
        fi
    fi
fi

log_info "Recovery DBL update check completed."
