# frozen_string_literal: true

require 'rumale/validation'
require 'rumale/evaluation_measure/r2_score'

module Rumale
  module Base
    # Module for all regressors in Rumale.
    module Regressor
      include Validation

      # An abstract method for fitting a model.
      def fit
        raise NotImplementedError, "#{__method__} has to be implemented in #{self.class}."
      end

      # An abstract method for predicting labels.
      def predict
        raise NotImplementedError, "#{__method__} has to be implemented in #{self.class}."
      end

      # Calculate the coefficient of determination for the given testing data.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) Testing data.
      # @param y [Xumo::DFloat] (shape: [n_samples, n_outputs]) Target values for testing data.
      # @return [Float] Coefficient of determination
      def score(x, y)
        x = check_convert_sample_array(x)
        y = check_convert_tvalue_array(y)
        check_sample_tvalue_size(x, y)
        evaluator = Rumale::EvaluationMeasure::R2Score.new
        evaluator.score(y, predict(x))
      end
    end
  end
end
