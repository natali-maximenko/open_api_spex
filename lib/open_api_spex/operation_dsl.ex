defmodule OpenApiSpex.OperationDsl do
  alias OpenApiSpex.OperationBuilder

  defmacro operation(action, spec) do
    operation_def(action, spec)
  end

  defmacro tags(tags) do
    tags_def(tags)
  end

  defmacro before_compile(_env) do
    quote do
      def spec_attributes, do: @spec_attributes

      def controller_tags do
        Module.get_attribute(__MODULE__, :controller_tags) || []
      end
    end
  end

  def operation_def(action, spec) do
    quote do
      if !Module.get_attribute(__MODULE__, :operation_defined) do
        Module.register_attribute(__MODULE__, :spec_attributes, accumulate: true)

        @before_compile {OpenApiSpex.OperationDsl, :before_compile}

        @operation_defined true
      end

      @spec_attributes {unquote(action), operation_spec(__MODULE__, unquote(spec))}
    end
  end

  def tags_def(tags) do
    quote do
      @controller_tags unquote(tags)
    end
  end

  def operation_spec(module, spec) do
    spec = Map.new(spec)
    tags = spec[:tags] || Module.get_attribute(module, :controller_tags)

    initial_attrs = [
      tags: tags,
      responses: [],
      parameters: OperationBuilder.build_parameters(spec)
    ]

    spec = Map.delete(spec, :parameters)

    struct!(OpenApiSpex.Operation, initial_attrs)
    |> struct!(spec)
  end
end
