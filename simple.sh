#!/bin/bash


/root/vms/qemu-10.0.3/build/qemu-system-aarch64 \
	-machine virt,accel=kvm \
	-cpu host \
	-smp 1 \
	-m 110M \
	-kernel ../picoboot/picoboot.elf \
	-netdev user,id=eth0 \
	-device virtio-net-device,netdev=eth0,mac=de:ad:be:ef:00:01 \
	-global virtio-mmio.force-legacy=false \
	-drive if=none,file=/space/disks/special.img,format=raw,id=vdisk \
	-device virtio-blk-device,drive=vdisk,bus=virtio-mmio-bus.0 \
	-nographic

	#-machine virt,virtualization=on,memory-backend=pc.ram \
	#-object memory-backend-file,id=pc.ram,size=256M,mem-path=/space/memories/1.img \
