defmodule LAP2.Utils.JsonUtilsTest do
  use ExUnit.Case

  alias LAP2.Utils.JsonUtils

  describe "parse_json/1" do
    test "Decode valid JSON" do
      json_bin = "{\"a\":1,\"b\":\"test\",\"c\":[1,2,3]}"
      expected_map = %{"a" => 1, "b" => "test", "c" => [1, 2, 3]}
      assert JsonUtils.parse_json(json_bin) == expected_map
    end

    test "Decode invalid JSON" do
      json_bin = "{\"a\":1,\"b\":\"test\",\"c\":[1,2,3}"
      expected_map = %{}
      assert JsonUtils.parse_json(json_bin) == expected_map
    end
  end

  describe "keys_to_atoms" do
    test "Replace key strings with atoms" do
      initial_map = %{"a" => 1, "b" => "test", "c" => [1, 2, 3]}
      expected_map = %{a: 1, b: "test", c: [1, 2, 3]}
      assert JsonUtils.keys_to_atoms(initial_map) == expected_map
    end
  end

  describe "values_to_atoms/2" do
    test "Replace value strings with atoms" do
      initial_map = %{a: 1, b: "test", c: [1, 2, 3]}
      expected_map = %{a: 1, b: :test, c: [1, 2, 3]}
      assert JsonUtils.values_to_atoms(initial_map, :b) == expected_map
    end

    test "Provide non-existent key" do
      initial_map = %{a: 1, b: "test", c: [1, 2, 3]}
      expected_map = %{a: 1, b: "test", c: [1, 2, 3]}
      assert JsonUtils.values_to_atoms(initial_map, :d) == expected_map
    end
  end
end
