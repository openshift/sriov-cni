#!/bin/bash

set -x

# usage:
# ./hack/image_test_rhel <docker|podman>

OCI_RUNTIME=$1
IMAGE_UNDER_TEST=sriov-test

"${OCI_RUNTIME}" build -t "${IMAGE_UNDER_TEST}" -f ./Dockerfile.rhel .

OUT_DEFAULT=$(mktemp -d)
OUT_RHEL9=$(mktemp -d)
OUT_RHEL8=$(mktemp -d)
TESTDATA="$(dirname -- "${BASH_SOURCE[0]}")"/testdata


"${OCI_RUNTIME}" run -v "${OUT_DEFAULT}:/out" "${IMAGE_UNDER_TEST}" --cni-bin-dir=/out --no-sleep
"${OCI_RUNTIME}" run -v "${TESTDATA}/rhel8-etc-os-release:/host/etc/os-release" -v "${OUT_RHEL8}:/out" "${IMAGE_UNDER_TEST}" --cni-bin-dir=/out --no-sleep
"${OCI_RUNTIME}" run -v "${TESTDATA}/rhel9-etc-os-release:/host/etc/os-release" -v "${OUT_RHEL9}:/out" "${IMAGE_UNDER_TEST}" --cni-bin-dir=/out --no-sleep

if ! "${OCI_RUNTIME}"  run -e CNI_COMMAND=VERSION -v "${OUT_RHEL8}/sriov:/sriov" registry.access.redhat.com/ubi8/ubi /sriov ; then
    echo "RHEL8 binary does not run on ubi8 image"
    exit 1
fi

if ! "${OCI_RUNTIME}"  run -e CNI_COMMAND=VERSION -v "${OUT_RHEL9}/sriov:/sriov" registry.access.redhat.com/ubi9/ubi /sriov ; then
    echo "RHEL9 binary does not run on ubi9 image"
    exit 1
fi

cmp "${OUT_DEFAULT}/sriov" "${OUT_RHEL9}/sriov" || { echo "default and RHEL9 binaries differ"; exit 1; }

exit 0

