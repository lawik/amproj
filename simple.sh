#!/bin/bash

qemu-system-aarch64 \
	-machine virt,virtualization=on \
	-cpu cortex-a53 \
	-smp 1 \
	-m 256M \
	-kernel ../picoboot/picoboot.elf \
	-netdev user,id=eth0 \
	-device virtio-net-device,netdev=eth0,mac=00:00:00:00:00:01 \
	-global virtio-mmio.force-legacy=false \
	-drive if=none,file=/space/disks/1.img,format=raw,id=vdisk \
	-device virtio-blk-device,drive=vdisk,bus=virtio-mmio-bus.0 \
	-nographic

	#-machine virt,virtualization=on,memory-backend=pc.ram \
	#-object memory-backend-file,id=pc.ram,size=256M,mem-path=/space/memories/1.img \
