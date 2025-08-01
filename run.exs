#!/usr/bin/env elixir

Mix.install([
  :muontrap,
  :bandit
])

Application.put_env(:this, :thing, self())

defmodule Router do
  use Plug.Router
  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    pid = Application.get_env(:this, :thing)
    send(pid, :started)
    send_resp(conn, 200, "Hello, World!")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end

bandit = {Bandit, plug: Router, scheme: :http, port: 4000, ip: {0,0,0,0}}
{:ok, _} = Supervisor.start_link([bandit], strategy: :one_for_one)


defmodule Emu do
  def child_spec(macaddr, disk_image) do
#    mem_dir = System.get_env("MEM_DIR", "memories")
#    mem_path = Path.join(mem_dir, "#{macaddr}.img")
    %{
      id: "mt-#{macaddr}",
      start: {
        Emu,
        :start_link,
        [
          macaddr,
          "qemu-system-aarch64",
          [
            "-machine", "virt,accel=kvm",
            "-cpu", "host",
            "-smp", "1",
            "-m", "200M",
            "-kernel", "../picoboot/picoboot.elf",
            "-netdev", "user,id=eth0",
            "-device", "virtio-net-device,netdev=eth0,mac=#{macaddr}",
            "-global", "virtio-mmio.force-legacy=false",
            "-drive", "if=none,file=#{disk_image},format=raw,id=vdisk",
            "-device", "virtio-blk-device,drive=vdisk,bus=virtio-mmio-bus.0",
            "-nographic"
          ],
          #[logger_fun: &IO.puts/1]
          []
        ]
      }
    }
  end

  def start_link(id, command, args, opts) do
    IO.puts("Starting #{id}")
    arg_string = Enum.join(args, " ")
    IO.puts("#{command} #{arg_string}")
    MuonTrap.Daemon.start_link(command, args, opts)
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

defmodule Util do
  def get_new_limit(current) do
    case IO.gets("new limit:") do
      data when is_binary(data) ->
        case Integer.parse(data) do
          :error ->
            IO.puts("bad input")
            get_new_limit(current)
          {num, _} ->
            if num > current do
              num
            else
              IO.puts("Less than current: #{current}")
            end
        end

      _ ->
        IO.puts("bad input")
        get_new_limit(current)
    end
  end
end

dir = System.get_env("DISK_DIR", "disks")
File.mkdir_p!(dir)

limit = 100_000
count = System.get_env("COUNT", "2000") |> Integer.parse() |> elem(0)
chunk = System.get_env("CHUNK", "100") |> Integer.parse() |> elem(0)
delay = System.get_env("DELAY", "10") |> Integer.parse() |> elem(0)

IO.puts("Count: #{count}")
IO.puts("Chunk: #{chunk}")
IO.puts("Delay: #{delay}")

#children =
  1..limit
  |> Enum.chunk_every(chunk)
  |> Enum.with_index()
  |> Enum.each(fn {ch, index} ->
    stop_at = Process.get(:limit, count)
    batch = index + 1
    current = batch * chunk
    children =
      ch
      |> Enum.map(fn i ->
        disk = Path.join(dir, "#{i}.img")
        if not File.exists?(disk) do
          IO.puts("Copying disk for #{i}")
          File.cp!("proj.img", disk)
        end
        mac = MacAddress.consistent(i)
        Emu.child_spec(mac, disk)
        #IO.puts("Waiting for start...")
        #receive do
        #  :started ->
        #    IO.puts("Started #{i}")
        #end
      end)
    IO.puts("Starting batch #{batch}: #{current} of #{stop_at}")
    Supervisor.start_link(children, strategy: :one_for_one)
    IO.puts("Supervisor started for #{Enum.count(children)} in #{batch}: #{current} of #{stop_at}.")
    IO.puts("Sleeping #{delay} seconds to allow some boot time...")
    if current <= stop_at do
      :timer.sleep(delay * 1000)
    else
      new = Util.get_new_limit(stop_at)
      Process.put(:limit, new)
    end

  end)

:timer.sleep(:infinity)
