#!/bin/sh
#set -x

XORG_CONF_DIR=/etc/X11/xorg.conf.d
XORG_USER_CONF_DIR=/usr/share/X11/xorg.conf.d
GPUCONF=10-gpu-mode.conf
GPU_USER_CONF=10-nvidia-drm-outputclass.conf
#SWITCHGL=/root/switchgl.sh
DEBUG=1
DEBUGLOG=/tmp/dyn-xorg-conf.log

# Removal of nvidia driver fails, this is either on init of Xorg, or because of a call at a similar time to xrandr.
# Get around this in a hacky way - put in an arbitrary delay in seconds.
DELAY_HACK=5

configureXorgDriver() {
  local symlinkName=${1:-}
  local symlinkName2=${2:-}
  dieIfNotSymlink "${XORG_CONF_DIR}/${GPUCONF}"
  dieIfNotSymlink "${XORG_USER_CONF_DIR}/${GPU_USER_CONF}"
  rm -f "${XORG_CONF_DIR}/${GPUCONF}"
  rm -f "${XORG_USER_CONF_DIR}/${GPU_USER_CONF}"
  ln -s "${symlinkName}" "${XORG_CONF_DIR}/${GPUCONF}"
  ln -s "${symlinkName2}" "${XORG_USER_CONF_DIR}/${GPU_USER_CONF}"
}

configureXorgForPrime() {
  local CONF=${XORG_CONF_DIR}/${GPUCONF}.prime
  local USER_CONF=${XORG_USER_CONF_DIR}/${GPU_USER_CONF}.prime
  configureXorgDriver ${CONF} ${USER_CONF}
#  ${SWITCHGL} NVIDIA
}

configureXorgForIntel() {
  local CONF=${XORG_CONF_DIR}/${GPUCONF}.intel
  local USER_CONF=${XORG_USER_CONF_DIR}/${GPU_USER_CONF}.intel
  configureXorgDriver ${CONF} ${USER_CONF}
#  ${SWITCHGL} MESA
  disableGPU
}

disableGPU() {
  sleep $DELAY_HACK
  [[ $(isModuleLoaded nvidia) -eq 1 ]] && echo "Found NVIDIA module. Attempting to remove." && rmmod nvidia_drm && rmmod nvidia_modeset && rmmod nvidia
  [[ $(isModuleLoaded bbswitch) -ne 1 ]] && modprobe bbswitch
  echo OFF > /proc/acpi/bbswitch
}

isModuleLoaded() {
  local module="$1"
  HASMOD=$(lsmod | grep "$1" | wc -l)
  [[ 0 -lt $HASMOD ]] && echo 1 && return 0
  echo 0
}

dieIfNotSymlink() {
  local testfile=${1:-}
  [[ ! -s ${testfile} ]] && [[ -e ${testfile} ]] && die "${testfile} is not a symlink."
}

die() {
  debug "${1:-}"
  echo {$1:-} 1>&2
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

WANTED_CONF=$(getKernelArgument gpuconf)


# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root to change xorg config!" 1>&2
   exit 1
fi

case "$WANTED_CONF" in
        "prime")
    debug "GOT: $WANTED_CONF. Calling configureXorgForPrime"
                configureXorgForPrime
                # glvnd makes this obsolete /root/bin/install-nvidia.bash
                ;;
        "intel")
    debug "GOT: $WANTED_CONF. Calling configureXorgForIntel"
                configureXorgForIntel
                # glvnd makes this obsolete /root/bin/install-mesa.bash
                ;;
        "none")
                ;;
        *)
    debug "GOT: no argument"
    echo "Got no argument"
    ;;
esac

