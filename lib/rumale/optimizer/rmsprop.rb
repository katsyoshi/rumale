# frozen_string_literal: true

require 'rumale/validation'
require 'rumale/base/base_estimator'

module Rumale
  module Optimizer
    # RMSProp is a class that implements RMSProp optimizer.
    #
    # *Reference*
    # - I. Sutskever, J. Martens, G. Dahl, and G. Hinton, "On the importance of initialization and momentum in deep learning," Proc. ICML' 13, pp. 1139--1147, 2013.
    # - G. Hinton, N. Srivastava, and K. Swersky, "Lecture 6e rmsprop," Neural Networks for Machine Learning, 2012.
    class RMSProp
      include Base::BaseEstimator
      include Validation

      # Create a new optimizer with RMSProp.
      #
      # @param learning_rate [Float] The initial value of learning rate.
      # @param momentum [Float] The initial value of momentum.
      # @param decay [Float] The smooting parameter.
      def initialize(learning_rate: 0.01, momentum: 0.9, decay: 0.9)
        check_params_numeric(learning_rate: learning_rate, momentum: momentum, decay: decay)
        check_params_positive(learning_rate: learning_rate, momentum: momentum, decay: decay)
        @params = {}
        @params[:learning_rate] = learning_rate
        @params[:momentum] = momentum
        @params[:decay] = decay
        @moment = nil
        @update = nil
      end

      # Calculate the updated weight with RMSProp adaptive learning rate.
      #
      # @param weight [Xumo::DFloat] (shape: [n_features]) The weight to be updated.
      # @param gradient [Xumo::DFloat] (shape: [n_features]) The gradient for updating the weight.
      # @return [Xumo::DFloat] (shape: [n_feautres]) The updated weight.
      def call(weight, gradient)
        @moment ||= Xumo::DFloat.zeros(weight.shape[0])
        @update ||= Xumo::DFloat.zeros(weight.shape[0])
        @moment = @params[:decay] * @moment + (1.0 - @params[:decay]) * gradient**2
        @update = @params[:momentum] * @update - (@params[:learning_rate] / (@moment**0.5 + 1.0e-8)) * gradient
        weight + @update
      end

      # Dump marshal data.
      # @return [Hash] The marshal data.
      def marshal_dump
        { params: @params,
          moment: @moment,
          update: @update }
      end

      # Load marshal data.
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @moment = obj[:moment]
        @update = obj[:update]
        nil
      end
    end
  end
end
