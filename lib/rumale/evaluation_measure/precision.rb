# frozen_string_literal: true

require 'rumale/base/evaluator'
require 'rumale/evaluation_measure/precision_recall'

module Rumale
  # This module consists of the classes for model evaluation.
  module EvaluationMeasure
    # Precision is a class that calculates the preicision of the predicted labels.
    #
    # @example
    #   evaluator = Rumale::EvaluationMeasure::Precision.new
    #   puts evaluator.score(ground_truth, predicted)
    class Precision
      include Base::Evaluator
      include EvaluationMeasure::PrecisionRecall

      # Return the average type for calculation of precision.
      # @return [String] ('binary', 'micro', 'macro')
      attr_reader :average

      # Create a new evaluation measure calculater for precision score.
      #
      # @param average [String] The average type ('binary', 'micro', 'macro')
      def initialize(average: 'binary')
        check_params_string(average: average)
        @average = average
      end

      # Calculate average precision.
      #
      # @param y_true [Xumo::Int32] (shape: [n_samples]) Ground truth labels.
      # @param y_pred [Xumo::Int32] (shape: [n_samples]) Predicted labels.
      # @return [Float] Average precision
      def score(y_true, y_pred)
        y_true = check_convert_label_array(y_true)
        y_pred = check_convert_label_array(y_pred)

        case @average
        when 'binary'
          precision_each_class(y_true, y_pred).last
        when 'micro'
          micro_average_precision(y_true, y_pred)
        when 'macro'
          macro_average_precision(y_true, y_pred)
        end
      end
    end
  end
end
