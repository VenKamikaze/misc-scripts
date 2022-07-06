#!/bin/sh
#set -x

DEBUG=1
DEBUGLOG=/tmp/switch-gpu.log

echo '---------------' > ${DEBUGLOG}
debug $(date '+%F %T')

isModuleLoaded() {
  local module="$1"
  HASMOD=$(lsmod | grep "$1" | wc -l)
  [[ 0 -lt $HASMOD ]] && echo 1 && return 0
  echo 0
}

die() {
  debug "${1:-}"
  echo ${1:-} 1>&2
  exit 1
}

getKernelArgument() {
  local ARG=${1:-}
  TARGET=$(grep -oP '(?<=\b'${ARG}'\=).*\b' /proc/cmdline)
  echo ${TARGET}
}

debug() {
  [[ ${DEBUG} -eq 1 ]] && echo "$1" >> ${DEBUGLOG}
}


disableVfioDrivers() {
  VFIO_DRVS=('vfio_iommu_type1' 'vfio_pci' 'vfio_pci_core' 'vfio_virqfd' 'vfio')
  VFIOCONF=/etc/modprobe.d/vfio.conf
  for vfiodrv in ${VFIO_DRVS[@]}; do
    [[ $(isModuleLoaded $vfiodrv) -eq 1 ]] && debug "Unloading ${vfiodrv}" && rmmod ${vfiodrv}
  done

}

disableVfioConf() {
  if [[ -f "${VFIOCONF}" ]]; then
    debug "Renaming ${VFIOCONF}{,.disabled}..."
    mv "${VFIOCONF}"{,.disabled}
  fi
}

enableVfioConf() {
  if [[ -f "${VFIOCONF}" ]]; then
    debug "Renaming ${VFIOCONF}{.disabled,}..."
    mv "${VFIOCONF}"{.disabled,}
  fi
}

enableAmdForHost() {
  disableVfioDrivers
  disableVfioConf
  debug "VFIO drivers removed..."

  [[ $(isModuleLoaded amdgpu) -eq 1 ]] && debug "Unloading amdgpu" && rmmod amdgpu
  sleep 2
  debug "Loading amdgpu"
  modprobe amdgpu

  enableVfioConf
}

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   die "This script must be run as root!"
   exit 1
fi

WANTED_CONF=$(getKernelArgument gpuconf)

case "$WANTED_CONF" in
        "amdhost")
    debug "GOT: $WANTED_CONF. Calling enableAmdForHost"
                enableAmdForHost
                ;;
        "amdvfio")
    debug "GOT: $WANTED_CONF. Nothing to do"
                ;;
        "none")
                ;;
        *)
    debug "GOT: no argument"
    echo "Got no argument"
    ;;
esac

