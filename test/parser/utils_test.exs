defmodule Temple.Parser.UtilsTest do
  use ExUnit.Case, async: true

  alias Temple.Parser.Utils

  describe "compile_attrs/1" do
    test "returns a list of text nodes for static attributes" do
      attrs = [class: "text-red", id: "error", phx_submit: :save, data_number: 99]

      actual = Utils.compile_attrs(attrs)

      assert [
               {:text, ~s' class="text-red"'},
               {:text, ~s' id="error"'},
               {:text, ~s' phx-submit="save"'},
               {:text, ~s' data-number="99"'}
             ] == actual
    end

    test "returns a list of text and expr nodes for attributes with runtime values" do
      class_ast = quote(do: @class)
      id_ast = quote(do: @id)
      attrs = [class: class_ast, id: id_ast, disabled: false, checked: true]

      actual = Utils.compile_attrs(attrs)

      assert [
               {:text, ~s' class="'},
               {:expr, class_ast},
               {:text, ~s'"'},
               {:text, ~s' id="'},
               {:expr, id_ast},
               {:text, ~s'"'},
               {:text, ~s' checked'}
             ] == actual
    end

    test "returns a list of text and expr nodes for the class object syntax" do
      class_ast = quote(do: @class)

      list =
        quote do
          ["text-red": unquote(class_ast)]
        end

      expr =
        quote do
          String.trim_leading(for {class, true} <- unquote(list), into: "", do: " #{class}")
        end

      attrs = [class: ["text-red": class_ast]]

      actual = Utils.compile_attrs(attrs)

      assert [
               {:text, ~s' class="'},
               {:expr, result_expr},
               {:text, ~s'"'}
             ] = actual

      # the ast metadata is different, let's just compare stringified versions
      assert Macro.to_string(result_expr) == Macro.to_string(expr)
    end
  end
end
