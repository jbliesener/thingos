setenv load_addr "0x44000000"
setenv rootfstype "ext4"
setenv devtype "mmc"

echo "Boot script loaded from ${devtype} ${devnum}"

if mmc dev 1; then
    setenv rootdev "/dev/mmcblk1p2"
    setenv devnum 1
    echo "Booting from SD card"
else
    setenv rootdev "/dev/mmcblk3p2"
    setenv devnum 0
    echo "Booting from eMMC"
fi

if test -e ${devtype} ${devnum} uEnv.txt; then
    load ${devtype} ${devnum} ${load_addr} uEnv.txt
    env import -t ${load_addr} ${filesize}
fi

setenv bootargs "root=${rootdev} rootfstype=${rootfstype} ${cmdline}"
if test -n "${initrd}"; then
    setenv bootargs "${bootargs} initrd=${initrd}"
    load ${devtype} ${devnum} ${ramdisk_addr_r} ${initrd}
    setenv initrd_size ${filesize}
fi

load ${devtype} ${devnum} ${kernel_addr_r} ${kernel}
load ${devtype} ${devnum} ${fdt_addr_r} ${fdt}
fdt addr ${fdt_addr_r}
fdt resize 65536
for overlay_file in ${overlays}; do
    if load ${devtype} ${devnum} ${load_addr} overlays/${overlay_file}.dtbo; then
        echo "Applying kernel provided DT overlay ${overlay_file}.dtbo"
        fdt apply ${load_addr}
    fi
done

echo "Boot args: ${bootargs}"
if test -n "${initrd}"; then
    echo "Initrd size is ${initrd_size}"
    bootz ${kernel_addr_r} ${ramdisk_addr_r}:${initrd_size} ${fdt_addr_r}
else
    bootz ${kernel_addr_r} - ${fdt_addr_r}
fi
