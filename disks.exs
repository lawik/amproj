#!/usr/bin/env elixir

[count] = System.argv()
count = count |> Integer.parse() |> elem(0)

source = "/space/disks/base.img"
File.cp!("./proj.img", source)

1..count
|> Task.async_stream(fn n ->
  target = "/space/disks/#{n}.img"
  if not File.exists?(target) do
    System.cmd("cp", [source, target])
    #File.cp!(source, target)
    "Copied #{n}.img"
  else
   "Skip #{n}.img"
  end
end, timeout: 60_000, ordered: false, max_concurrency: 4)
|> Enum.each(fn out ->
IO.inspect(out)
end)
