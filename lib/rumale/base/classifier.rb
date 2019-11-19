# frozen_string_literal: true

require 'rumale/validation'
require 'rumale/evaluation_measure/accuracy'

module Rumale
  module Base
    # Module for all classifiers in Rumale.
    module Classifier
      include Validation

      # An abstract method for fitting a model.
      def fit
        raise NotImplementedError, "#{__method__} has to be implemented in #{self.class}."
      end

      # An abstract method for predicting labels.
      def predict
        raise NotImplementedError, "#{__method__} has to be implemented in #{self.class}."
      end

      # Calculate the mean accuracy of the given testing data.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) Testing data.
      # @param y [Xumo::Int32] (shape: [n_samples]) True labels for testing data.
      # @return [Float] Mean accuracy
      def score(x, y)
        x = check_convert_sample_array(x)
        y = check_convert_label_array(y)
        check_sample_label_size(x, y)
        evaluator = Rumale::EvaluationMeasure::Accuracy.new
        evaluator.score(y, predict(x))
      end
    end
  end
end
