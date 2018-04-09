defmodule AsyncTest do
  use ExUnit.Case
  doctest Async

  test "can run async" do
    Async.run(fn () ->
      assert is_pid(self())
    end)
  end

end
