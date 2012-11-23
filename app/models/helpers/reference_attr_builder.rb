# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Helpers
  class ReferenceAttrBuilder
    class_attribute :valid_options
    self.valid_options = [:class, :polymorphic, :reader]

    attr_reader :model, :name, :options

    def self.build(model, name, options)
      self.new(model, name, options).build
    end

    def build
      validate_options
      define_helpers
      define_accessors
    end

    def initialize(model, name, options = {})
      @model, @name, @options = model, name, options
    end

    def polymorphic?
      options[:polymorphic]
    end

    def klass
      options[:class]
    end

    def reader
      options[:reader]
    end

    private
      def validate_options
        options.assert_valid_keys(self.class.valid_options)
      end

      def define_model_method(*args, &block)
        model.send :define_method, *args, &block
      end

      def define_helpers
        define_attribute_clear
        define_subattributes_clear
        define_load_data
      end

      def define_accessors
        define_readers
        define_writers
      end

      def define_attribute_clear
        attr = name
        define_model_method(clear_attribute_data_name) do
          self.instance_variable_set("@#{attr}", nil)
        end
      end

      def define_subattributes_clear
        attr = name
        polymorphic = polymorphic?
        define_model_method(clear_sub_attribute_data_name) do
          self.instance_variable_set("@#{attr}_id", nil)
          self.instance_variable_set("@#{attr}_type", nil) if polymorphic
        end
      end

      def define_load_data
        attr = name
        polymorphic = polymorphic?
        klass = self.klass
        reader = self.reader
        define_model_method(load_attribute_data_name) do
          data = self.instance_variable_get("@#{attr}")
          id = self.instance_variable_get("@#{attr}_id")
          type = polymorphic ? self.instance_variable_get("@#{attr}_type") : klass
          if !data && id && type
            klass_i = type.kind_of?(Class) ? type : type.constantize
            self.instance_variable_set("@#{attr}", klass_i.find(id))
          elsif data && (!id || !type)
            self.instance_variable_set("@#{attr}_id", data.id)
            self.instance_variable_set("@#{attr}_type", data.class.name) if polymorphic
          elsif !data && !id && reader
            data = self.instance_exec &reader
            if data
              self.instance_variable_set("@#{attr}", data)
              self.instance_variable_set("@#{attr}_id", data.id)
              self.instance_variable_set("@#{attr}_type", data.class.name) if polymorphic
            end
          end
        end
      end

      def define_readers
        def_attrs = [name, "#{name}_id"]
        load_method_name = load_attribute_data_name
        def_attrs << "#{name}_type" if polymorphic?
        def_attrs.each do |attr_name|
          define_model_method(attr_name) do
            value = self.instance_variable_get("@#{attr_name}")
            unless value
              self.send(load_method_name)
              value = self.instance_variable_get("@#{attr_name}")
            end
            value
          end
        end
      end

      def define_writers
        def_attrs = { name => clear_sub_attribute_data_name,
                      "#{name}_id" => clear_attribute_data_name}
        def_attrs["#{name}_type"] = clear_attribute_data_name if polymorphic?
        def_attrs.each do |attr_name, clear_method_name|
          define_model_method("#{attr_name}=".to_sym) do |value|
            self.instance_variable_set("@#{attr_name}", value)
            self.send(clear_method_name)
          end
        end
      end

      def clear_sub_attribute_data_name
        "_clear_sub_#{name}_data"
      end

      def clear_attribute_data_name
        "_clear_#{name}_data"
      end

      def load_attribute_data_name
        "_load_#{name}_data"
      end
  end
end
