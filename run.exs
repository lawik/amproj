#!/usr/bin/env elixir

Mix.install([:muontrap])

defmodule Emu do
  def child_spec(macaddr, disk_image) do
    {MuonTrap.Daemon, ["qemu-system-aarch64",
      [
        "-M", "virt,virtualization=on",
        "-cpu", "cortex-a53",
        "-smp", "1",
        "-m", "256M",
        "-kernel", "../picoboot/picoboot.elf",
        "-netdev", "user,id=eth0",
        "-device", "virtio-net-device,netdev=eth0,mac=#{macaddr}",
        "-global", "virtio-mmio.force-legacy=false",
        "-drive", "if=none,file=#{disk_image},format=raw,id=vdisk",
        "-device", "virtio-blk-device,drive=vdisk,bus=virtio-mmio-bus.0",
        "-nographic"
    ]
    ]}
  end
end

defmodule MacAddress do
  def generate_fake do
    1..6
    |> Enum.map(fn _ -> :rand.uniform(256) - 1 end)
    |> Enum.map(&Integer.to_string(&1, 16) |> String.pad_leading(2, "0"))
    |> Enum.join(":")
    |> String.upcase()
  end

  def consistent(num) do
    num
    |> Integer.to_string(16)
    |> String.pad_leading(12, "0")
    |> :binary.bin_to_list()
    |> Enum.chunk_every(2)
    |> Enum.map(&IO.iodata_to_binary/1)
    |> Enum.join(":")
  end
end

File.mkdir_p!("disks")
File.cp!("proj.img", "disks/1.img")
mac = MacAddress.consistent(1)
Supervisor.start_link([Emu.child_spec(mac, "disks/1.img")], strategy: :one_for_one)
:timer.sleep(:infinity)
