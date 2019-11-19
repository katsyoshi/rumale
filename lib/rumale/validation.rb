# frozen_string_literal: true

module Rumale
  # @!visibility private
  module Validation
    module_function

    # @!visibility private
    def check_convert_sample_array(x)
      x = Xumo::DFloat.cast(x) unless x.is_a?(Xumo::DFloat)
      raise ArgumentError, 'Expect sample matrix to be 2-D array' unless x.ndim == 2
      x
    end

    # @!visibility private
    def check_convert_label_array(y)
      y = Xumo::Int32.cast(y) unless y.is_a?(Xumo::Int32)
      raise ArgumentError, 'Expect label vector to be 1-D arrray' unless y.ndim == 1
      y
    end

    # @!visibility private
    def check_convert_tvalue_array(y)
      y = Xumo::DFloat.cast(y) unless y.is_a?(Xumo::DFloat)
      y
    end

    # @!visibility private
    def check_sample_array(x)
      raise TypeError, 'Expect class of sample matrix to be Xumo::DFloat' unless x.is_a?(Xumo::DFloat)
      raise ArgumentError, 'Expect sample matrix to be 2-D array' unless x.ndim == 2
      nil
    end

    # @!visibility private
    def check_label_array(y)
      raise TypeError, 'Expect class of label vector to be Xumo::Int32' unless y.is_a?(Xumo::Int32)
      raise ArgumentError, 'Expect label vector to be 1-D arrray' unless y.ndim == 1
      nil
    end

    # @!visibility private
    def check_tvalue_array(y)
      unless y.is_a?(Kernel.const_get("#{Xumo}").const_get("DFloat"))
        raise TypeError, 'Expect class of target value vector to be Xumo::DFloat'
      end
      nil
    end

    # @!visibility private
    def check_sample_label_size(x, y)
      raise ArgumentError, 'Expect to have the same number of samples for sample matrix and label vector' unless x.shape[0] == y.shape[0]
      nil
    end

    # @!visibility private
    def check_sample_tvalue_size(x, y)
      raise ArgumentError, 'Expect to have the same number of samples for sample matrix and target value vector' unless x.shape[0] == y.shape[0]
      nil
    end

    # @!visibility private
    def check_params_type(type, params = {})
      params.each { |k, v| raise TypeError, "Expect class of #{k} to be #{type}" unless v.is_a?(type) }
      nil
    end

    # @!visibility private
    def check_params_type_or_nil(type, params = {})
      params.each { |k, v| raise TypeError, "Expect class of #{k} to be #{type} or nil" unless v.is_a?(type) || v.is_a?(NilClass) }
      nil
    end

    # @!visibility private
    def check_params_numeric(params = {})
      check_params_type(Numeric, params)
    end

    # @!visibility private
    def check_params_numeric_or_nil(params = {})
      check_params_type_or_nil(Numeric, params)
    end

    # @!visibility private
    def check_params_float(params = {})
      check_params_type(Float, params)
    end

    # @!visibility private
    def check_params_integer(params = {})
      check_params_type(Integer, params)
    end

    # @!visibility private
    def check_params_string(params = {})
      check_params_type(String, params)
    end

    # @!visibility private
    def check_params_boolean(params = {})
      params.each { |k, v| raise TypeError, "Expect class of #{k} to be Boolean" unless v.is_a?(FalseClass) || v.is_a?(TrueClass) }
      nil
    end

    # @!visibility private
    def check_params_positive(params = {})
      params.reject { |_, v| v.nil? }.each { |k, v| raise ArgumentError, "Expect #{k} to be positive value" if v.negative? }
      nil
    end
  end
end
