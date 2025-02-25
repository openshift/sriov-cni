#!/bin/sh

# Always exit on errors.
set -e

# Give help text for parameters.
usage()
{
    printf "This is an entrypoint script for SR-IOV CNI to overlay its\n"
    printf "binary into location in a filesystem. The binary file will\n"
    printf "be copied to the corresponding directory.\n"
    printf "\n"
    printf "./entrypoint.sh\n"
    printf "\t-h --help\n"
    printf "\t--cni-bin-dir=%s\n" "$CNI_BIN_DIR"
    printf "\t--sriov-bin-file=%s\n" "$SRIOV_BIN_FILE"
    printf "\t--no-sleep\n"
}

get_source_folder_for_rhel_version()
{
    if [ ! -f /host/etc/os-release ]; then
        echo "/usr/bin"
        return
    fi

    # shellcheck source=/dev/null
    . /host/etc/os-release
    
    rhelmajor=
    # detect which version we're using in order to copy the proper binaries
    case "${ID}" in
        rhcos|scos)
            rhelmajor=$(echo "$RHEL_VERSION" | sed -E 's/([0-9]+)\.{1}[0-9]+(\.[0-9]+)?/\1/')
            if [ -z "$rhelmajor" -a "$ID" = scos ] ; then
                rhelmajor="$(echo "$PLATFORM_ID" | sed -E 's/^platform:el([0-9]+)$/\1/')"
            fi
        ;;
        rhel|centos) rhelmajor=$(echo "${VERSION_ID}" | cut -f 1 -d .)
        ;;
        fedora)
            if [ "${VARIANT_ID}" = "coreos" ]; then
            rhelmajor=8
            else
            echo "FATAL ERROR: Unsupported Fedora variant=${VARIANT_ID}"
            exit 1
            fi
        ;;
        *) echo "FATAL ERROR: Unsupported OS ID=${ID}"; exit 1
        ;;
        esac
        # Set which directory we'll copy from, detect if it exists
        sourcedir=/usr/bin
        case "${rhelmajor}" in
        8)
        sourcedir=/usr/bin/rhel8
        ;;
        9)
        sourcedir=/usr/bin/rhel9
        ;;
        *)
        echo "ERROR: RHEL Major Version Unsupported, rhelmajor=${rhelmajor}"
        ;;
    esac

    echo "${sourcedir}"
}

# Set known directories.
CNI_BIN_DIR="/host/opt/cni/bin"
SRIOV_BIN_FILE="$(get_source_folder_for_rhel_version)/sriov"
NO_SLEEP=0


# Parse parameters given as arguments to this script.
while [ "$1" != "" ]; do
    PARAM=$(echo "$1" | awk -F= '{print $1}')
    VALUE=$(echo "$1" | awk -F= '{print $2}')
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --cni-bin-dir)
            CNI_BIN_DIR=$VALUE
            ;;
        --sriov-bin-file)
            SRIOV_BIN_FILE=$VALUE
            ;;
        --no-sleep)
            NO_SLEEP=1
            ;;
        *)
            /bin/echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done


# Loop through and verify each location each.
for i in $CNI_BIN_DIR $SRIOV_BIN_FILE
do
  if [ ! -e "$i" ]; then
    /bin/echo "Location $i does not exist"
    exit 1;
  fi
done

# Copy file into proper place.
cp -f "$SRIOV_BIN_FILE" "$CNI_BIN_DIR"

if [ $NO_SLEEP -eq 1 ]; then
  exit 0
fi

echo "Entering sleep... (success)"
trap : TERM INT

# Sleep forever. 
# sleep infinity is not available in alpine; instead lets go sleep for ~68 years. Hopefully that's enough sleep
sleep 2147483647 & wait
