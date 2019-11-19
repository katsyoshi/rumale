# frozen_string_literal: true

require 'rumale/base/evaluator'

module Rumale
  module EvaluationMeasure
    # MeanSquaredError is a class that calculates the mean squared error.
    #
    # @example
    #   evaluator = Rumale::EvaluationMeasure::MeanSquaredError.new
    #   puts evaluator.score(ground_truth, predicted)
    class MeanSquaredError
      include Base::Evaluator

      # Calculate mean squared error.
      #
      # @param y_true [Xumo::DFloat] (shape: [n_samples, n_outputs]) Ground truth target values.
      # @param y_pred [Xumo::DFloat] (shape: [n_samples, n_outputs]) Estimated target values.
      # @return [Float] Mean squared error
      def score(y_true, y_pred)
        y_true = check_convert_tvalue_array(y_true)
        y_pred = check_convert_tvalue_array(y_pred)
        raise ArgumentError, 'Expect to have the same size both y_true and y_pred.' unless y_true.shape == y_pred.shape

        ((y_true - y_pred)**2).mean
      end
    end
  end
end
