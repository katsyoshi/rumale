# frozen_string_literal: true

require 'rumale/base/evaluator'
require 'rumale/preprocessing/label_binarizer'

module Rumale
  module EvaluationMeasure
    # LogLoss is a class that calculates the logarithmic loss of predicted class probability.
    #
    # @example
    #   evaluator = Rumale::EvaluationMeasure::LogLoss.new
    #   puts evaluator.score(ground_truth, predicted)
    class LogLoss
      include Base::Evaluator

      # Calculate mean logarithmic loss.
      # If both y_true and y_pred are array (both shapes are [n_samples]), this method calculates
      # mean logarithmic loss for binary classification.
      #
      # @param y_true [Xumo::Int32] (shape: [n_samples]) Ground truth labels.
      # @param y_pred [Xumo::DFloat] (shape: [n_samples, n_classes]) Predicted class probability.
      # @param eps [Float] A small value close to zero to avoid outputting infinity in logarithmic calcuation.
      # @return [Float] mean logarithmic loss
      def score(y_true, y_pred, eps = 1e-15)
        y_true = check_convert_label_array(y_true)
        y_pred = check_convert_tvalue_array(y_pred)

        n_samples, n_classes = y_pred.shape
        error_num = 0
        begin
          clipped_p = y_pred.clip(eps, 1 - eps)
        rescue Xumo::NArray::OperationError => e
          error_num += 1
          raise e if error_num > 5
          retry
        end

        log_loss = if n_classes.nil?
                     negative_label = y_true.to_a.uniq.min
                     bin_y_true = Xumo::DFloat.cast(y_true.ne(negative_label))
                     -(bin_y_true * Xumo::NMath.log(clipped_p) + (1 - bin_y_true) * Xumo::NMath.log(1 - clipped_p))
                   else
                     encoder = Rumale::Preprocessing::LabelBinarizer.new
                     encoded_y_true = Xumo::DFloat.cast(encoder.fit_transform(y_true))
                     clipped_p /= clipped_p.sum(1).expand_dims(1)
                     -(encoded_y_true * Xumo::NMath.log(clipped_p)).sum(1)
                   end
        log_loss.sum / n_samples
      end
    end
  end
end
