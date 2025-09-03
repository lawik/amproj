#!/usr/bin/env elixir

Mix.install([:sizeable])

defmodule KSM do
  def check_recursively do
    value = 
      "/sys/kernel/mm/ksm/general_profit"
      |> File.read!()
      |> Sizeable.filesize()
    
    IO.write("\r#{value}")
    :timer.sleep(1000)
    check_recursively()
  end
end

KSM.check_recursively()
