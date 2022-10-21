require 'json'
module Terrparty
  class HashBuilder
    attr_reader :_data
    attr_reader :_vars
    def initialize(file=nil)
      @_data = {}
      @_vars = {}
      @_file = file
    end

    def tp_value(key, value)
      _vars[key] = value
    end

    def load(f)
      eval(File.read(File.expand_path("../" + f, @_file)))
    end

    def exec(block)
      instance_exec &block
      [_data, _vars]
    end

    def get(keys)
      c = _data
      keys.each do |k|
        if c && c[k]
          c = c[k]
        else 
          c = nil
        end
      end
      c
    end

    def set(keys, v)
      c = _data
      keys[0..-2].each do |k|
        c[k] ||= {}
        c = c[k]
      end
      c[keys[-1]] = v
    end

    def _(*keys, &block)
      method_missing(*keys, &block)
    end

    def method_missing(*keys, &block)
      if block
        v, _ = HashBuilder.new.exec(block)
      else
        v = keys[-1] 
        keys = keys[0..-2]
      end

      if get(keys)
        unless get(keys).is_a?(Array)
          set(keys, [get(keys)])
        end
        get(keys) << v
      else
        set(keys, v)
      end
    end

  end

  class Builder
    attr_reader :data
    attr_reader :vars

    def initialize(file, &block)
      data, vars = HashBuilder.new(file).exec(block)
      @data, @vars = extract_vars(data, vars)
    end

    def extract_vars(data, vars)
      data[:variables]&.each do |name, definition|
        if definition[:tp_value]
          vars[name] = definition.delete(:tp_value)
        end
      end
      [data, vars]
    end

    def vars_to_json
      JSON.pretty_generate(vars)
    end

    def to_json
      JSON.pretty_generate(data)
    end
  end
end
