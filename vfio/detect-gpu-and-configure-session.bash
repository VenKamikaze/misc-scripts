#!/bin/bash
#
PRI_GPU=""

grep 'Matched amdgpu as autoconfigured driver 0' /var/log/Xorg.0.log
if [[ $(grep -o 'Matched amdgpu as autoconfigured driver 0' /var/log/Xorg.0.log) == "Matched amdgpu as autoconfigured driver 0" ]]; then
  PRI_GPU="AMD"
elif [[ $(grep -o 'Matched nvidia as autoconfigured driver 0' /var/log/Xorg.0.log) == "Matched nvidia as autoconfigured driver 0" ]]; then
  PRI_GPU="NVIDIA"
else
  PRI_GPU="Unknown"
fi

echo "Primary GPU: ${PRI_GPU}"
if [[ "${PRI_GPU}" == "AMD" ]]; then
  echo -n "Setting up ISCSI mount..."
  /usr/bin/bash /home/msaun/bin/iscsi-mount.bash
  echo -n "Mounting games on host..."
  sudo /usr/bin/bash /home/msaun/bin/mount-iscsi-games.bash
  echo "... DONE"
fi

if [[ "${PRI_GPU}" == "NVIDIA" ]]; then
  export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
fi
