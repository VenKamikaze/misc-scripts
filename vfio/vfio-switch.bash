#!/bin/bash
#
VFIO_ID_GPU="1002 73df"
ID_GPU="0000:0c:00.0"

generic_driver_action() {
  echo "${1:-}" > /sys/bus/pci/drivers/"${2:-}"/"${3:-}"
}

vfio_unbind() {
  generic_driver_action "${ID_GPU}" vfio-pci unbind
}

vfio_bind() {
  echo "${VFIO_ID_GPU}" > /sys/bus/pci/drivers/vfio-pci/new_id
  generic_driver_action "${ID_GPU}" vfio-pci bind
  echo "${VFIO_ID_GPU}" > /sys/bus/pci/drivers/vfio-pci/remove_id
}

amdgpu_unbind() {
  generic_driver_action "${ID_GPU}" amdgpu unbind
}

amdgpu_bind() {
  generic_driver_action "${ID_GPU}" amdgpu bind
}

USE="${1:-}"

[[ -z "${USE}" ]] && echo "Please specify vfio-pci or amdgpu" >&2 && exit 1

if [[ "${USE}" == "amdgpu" ]]; then
  vfio_unbind
  [[ $? -ne 0 ]] && echo "unbound vfio, binding amdgpu" && amdgpu_bind
elif [[ "${USE}" == "vfio-pci" ]]; then
  amdgpu_unbind
  [[ $? -ne 0 ]] && echo "unbound amdgpu, binding vfio" && vfio_bind
fi

##vfio_pci               16384  0
#vfio_pci_core          69632  1 vfio_pci
#irqbypass              16384  2 vfio_pci_core,kvm
#vfio_virqfd            16384  1 vfio_pci_core
#vfio_iommu_type1       40960  0
#vfio                   45056  2 vfio_pci_core,vfio_iommu_type1

#rmmod vfio_iommu_type1
#rmmod vfio_pci_core
#rmmod vfio_virqfd
#rmmod vfio_pci
#rmmod vfio
