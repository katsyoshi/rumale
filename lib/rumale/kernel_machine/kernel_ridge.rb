# frozen_string_literal: true

require 'rumale/base/base_estimator'
require 'rumale/base/regressor'

module Rumale
  module KernelMachine
    # KernelRidge is a class that implements kernel ridge regression.
    #
    # @example
    #   require 'numo/linalg/autoloader'
    #
    #   kernel_mat_train = Rumale::PairwiseMetric::rbf_kernel(training_samples)
    #   kridge = Rumale::KernelMachine::KernelRidge.new(reg_param: 1.0)
    #   kridge.fit(kernel_mat_train, traininig_values)
    #
    #   kernel_mat_test = Rumale::PairwiseMetric::rbf_kernel(test_samples, training_samples)
    #   results = kridge.predict(kernel_mat_test)
    class KernelRidge
      include Base::BaseEstimator
      include Base::Regressor

      # Return the weight vector.
      # @return [Xumo::DFloat] (shape: [n_training_sample, n_outputs])
      attr_reader :weight_vec

      # Create a new regressor with kernel ridge regression.
      #
      # @param reg_param [Float/Xumo::DFloat] The regularization parameter.
      def initialize(reg_param: 1.0)
        raise TypeError, 'Expect class of reg_param to be Float or Xumo::DFloat' unless reg_param.is_a?(Float) || reg_param.is_a?(Xumo::DFloat)
        raise ArgumentError, 'Expect reg_param array to be 1-D arrray' if reg_param.is_a?(Xumo::DFloat) && reg_param.shape.size != 1
        @params = {}
        @params[:reg_param] = reg_param
        @weight_vec = nil
      end

      # Fit the model with given training data.
      #
      # @param x [Xumo::DFloat] (shape: [n_training_samples, n_training_samples])
      #   The kernel matrix of the training data to be used for fitting the model.
      # @param y [Xumo::DFloat] (shape: [n_samples, n_outputs]) The taget values to be used for fitting the model.
      # @return [KernelRidge] The learned regressor itself.
      def fit(x, y)
        x = check_convert_sample_array(x)
        y = check_convert_tvalue_array(y)
        check_sample_tvalue_size(x, y)
        raise ArgumentError, 'Expect the kernel matrix of training data to be square.' unless x.shape[0] == x.shape[1]
        raise 'KernelRidge#fit requires Xumo::Linalg but that is not loaded.' unless enable_linalg?

        n_samples = x.shape[0]

        if @params[:reg_param].is_a?(Float)
          reg_kernel_mat = x + Xumo::DFloat.eye(n_samples) * @params[:reg_param]
          @weight_vec = Xumo::Linalg.solve(reg_kernel_mat, y, driver: 'sym')
        else
          raise ArgumentError, 'Expect y and reg_param to have the same number of elements.' unless y.shape[1] == @params[:reg_param].shape[0]
          n_outputs = y.shape[1]
          @weight_vec = Xumo::DFloat.zeros(n_samples, n_outputs)
          n_outputs.times do |n|
            reg_kernel_mat = x + Xumo::DFloat.eye(n_samples) * @params[:reg_param][n]
            @weight_vec[true, n] = Xumo::Linalg.solve(reg_kernel_mat, y[true, n], driver: 'sym')
          end
        end

        self
      end

      # Predict values for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_testing_samples, n_training_samples])
      #     The kernel matrix between testing samples and training samples to predict values.
      # @return [Xumo::DFloat] (shape: [n_samples, n_outputs]) Predicted values per sample.
      def predict(x)
        x = check_convert_sample_array(x)
        x.dot(@weight_vec)
      end

      # Dump marshal data.
      # @return [Hash] The marshal data.
      def marshal_dump
        { params: @params,
          weight_vec: @weight_vec }
      end

      # Load marshal data.
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @weight_vec = obj[:weight_vec]
        nil
      end
    end
  end
end
