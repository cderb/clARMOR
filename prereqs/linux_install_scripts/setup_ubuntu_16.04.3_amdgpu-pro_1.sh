#!/bin/bash
# Copyright (c) 2016-2017 Advanced Micro Devices, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# The following script will set up a fresh Ubuntu 16.04.3 LTS installation
# with the AMDGPU-Pro drivers and the AMD APP SDK 3.0. 

# Note that there's very likely some overkill on the installs here. This is
# based off a more comprehensive set of installation directions for a larger
# set of tools inside AMD Research.
# A lot of the X11 libraries are needed for benchmarks like Phoronix, however.

#==============================================================================
#Install Ubuntu 16.04.3 LTS
#==============================================================================
# Use USB thumb drive with Ubuntu 16.04.3 LTS installed to boot
# After booted, select install Ubuntu, put it on your local hard disk, then:

#==============================================================================

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
INSTALLER_DIR=${BASE_DIR}/../install_files/
REAL_USER=`logname 2>/dev/null || echo ${SUDO_USER:-${USER}}`
su -c "mkdir -p ${INSTALLER_DIR}" $REAL_USER


#Do basic post-install stuff
#==============================================================================
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install git openssh-server

#Install AMDGPU-Pro Driver
su -c "mkdir -p ~/Downloads/software/" $REAL_USER
cd ~/Downloads/software
wget https://www2.ati.com/drivers/linux/ubuntu/amdgpu-pro-17.40-492261.tar.xz --referer=support.amd.com
if [ $? -ne 0 ]; then
    echo -e "FAILED to download the AMDGPU-Pro Drivers."
    echo -e "Exiting installation script without doing anything else."
    exit -1
fi
tar -xf amdgpu-pro-17.40-492261.tar.xz
sudo ./amdgpu-pro-17.40-492261/amdgpu-pro-install -y --compute

sudo cp -r /opt/amdgpu-pro/lib/x86_64-linux-gnu /opt/amdgpu-pro/lib/x86_64
sudo cp -a /opt/amdgpu-pro/lib/x86_64-linux-gnu/*.so* /usr/lib/.

sudo cp -r /opt/amdgpu-pro/bin /opt/amdgpu-pro/binx86_64
sudo mv /opt/amdgpu-pro/binx86_64 /opt/amdgpu-pro/bin/x86_64

#Download the AMD APP SDK
#==============================================================================
cd ${INSTALLER_DIR}
echo "Downloading the AMD APP SDK"
${BASE_DIR}/../support_files/get_amd_app_sdk.sh -d $(pwd)

sudo mkdir -p /opt/amdgpu-pro/include
sudo cp -r ${INSTALLER_DIR}/AMDAPP/include/CL /opt/amdgpu-pro/include/.
sudo sh -c 'echo export AMDAPPSDKROOT=/opt/amdgpu-pro > /etc/profile.d/gpupro_ocl.sh'
sudo sh -c 'echo export PATH=\$PATH:/opt/amdgpu-pro/bin/ >> /etc/profile.d/gpupro_ocl.sh'


#Set up the next script to run after the upcoming reboot.
#===============================================================================
INIT_FILE="amdgpu-pro_setup"
NEXT_SCRIPT=setup_ubuntu_16.04.3_amdgpu-pro_2.sh
sudo sh -c "echo '#!/bin/bash' > /etc/init.d/${INIT_FILE}"
sudo sh -c "echo ${BASE_DIR}/${NEXT_SCRIPT} >> /etc/init.d/${INIT_FILE}"
sudo chmod 755 /etc/init.d/${INIT_FILE}

sudo sh -c "echo [Desktop Entry] > /etc/xdg/autostart/${INIT_FILE}.desktop"
sudo sh -c "echo Name=${INIT_FILE} >> /etc/xdg/autostart/${INIT_FILE}.desktop"
sudo sh -c "echo Terminal=true >> /etc/xdg/autostart/${INIT_FILE}.desktop"
sudo sh -c "echo Exec=/etc/init.d/${INIT_FILE} >> /etc/xdg/autostart/${INIT_FILE}.desktop"
sudo sh -c "echo Type=Application >> /etc/xdg/autostart/${INIT_FILE}.desktop"
sudo sh -c "echo Categories=Utility\; >> /etc/xdg/autostart/${INIT_FILE}.desktop"

#Reboot at this point
#==============================================================================
sudo reboot
#==============================================================================
