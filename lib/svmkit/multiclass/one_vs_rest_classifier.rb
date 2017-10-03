require 'svmkit/base/base_estimator.rb'
require 'svmkit/base/classifier.rb'

module SVMKit
  # This module consists of the classes that implement multi-label classification strategy.
  module Multiclass
    # OneVsRestClassifier is a class that implements One-vs-Rest (OvR) strategy for multi-label classification.
    #
    #   base_estimator =
    #    SVMKit::LinearModel::PegasosSVC.new(penalty: 1.0, max_iter: 100, batch_size: 20, random_seed: 1)
    #   estimator = SVMKit::Multiclass::OneVsRestClassifier.new(estimator: base_estimator)
    #   estimator.fit(training_samples, training_labels)
    #   results = estimator.predict(testing_samples)
    #
    class OneVsRestClassifier
      include Base::BaseEstimator
      include Base::Classifier

      DEFAULT_PARAMS = { # :nodoc:
        estimator: nil
      }.freeze

      # The set of estimators.
      attr_reader :estimators

      # The class labels.
      attr_reader :classes

      # Create a new multi-label classifier with the one-vs-rest startegy.
      #
      # :call-seq:
      #   new(estimator: base_estimator) -> OneVsRestClassifier
      #
      # * *Arguments* :
      #   - +:estimator+ (Classifier) (defaults to: nil) -- The (binary) classifier for construction a multi-label classifier.
      def initialize(params = {})
        self.params = DEFAULT_PARAMS.merge(Hash[params.map { |k, v| [k.to_sym, v] }])
        @estimators = nil
        @classes = nil
      end

      # Fit the model with given training data.
      #
      # :call-seq:
      #   fit(x, y) -> OneVsRestClassifier
      #
      # * *Arguments* :
      #   - +x+ (NMatrix, shape: [n_samples, n_features]) -- The training data to be used for fitting the model.
      #   - +y+ (NMatrix, shape: [1, n_samples]) -- The labels to be used for fitting the model.
      # * *Returns* :
      #   - The learned classifier itself.
      def fit(x, y)
        @classes = y.uniq.sort
        @estimators = @classes.map do |label|
          bin_y = y.map { |l| l == label ? 1 : -1 }
          params[:estimator].dup.fit(x, bin_y)
        end
        self
      end

      # Calculate confidence scores for samples.
      #
      # :call-seq:
      #   decision_function(x) -> NMatrix, shape: [n_samples, n_classes]
      #
      # * *Arguments* :
      #   - +x+ (NMatrix, shape: [n_samples, n_features]) -- The samples to compute the scores.
      # * *Returns* :
      #   - Confidence scores per sample for each class.
      def decision_function(x)
        n_samples, = x.shape
        n_classes = @classes.size
        NMatrix.new(
          [n_classes, n_samples],
          Array.new(n_classes) { |m| @estimators[m].decision_function(x).to_a }.flatten
        ).transpose
      end

      # Predict class labels for samples.
      #
      # :call-seq:
      #   predict(x) -> NMatrix, shape: [1, n_samples]
      #
      # * *Arguments* :
      #   - +x+ (NMatrix, shape: [n_samples, n_features]) -- The samples to predict the labels.
      # * *Returns* :
      #   - Predicted class label per sample.
      def predict(x)
        n_samples, = x.shape
        decision_values = decision_function(x)
        NMatrix.new([1, n_samples],
                    decision_values.each_row.map { |vals| @classes[vals.to_a.index(vals.to_a.max)] })
      end

      # Claculate the mean accuracy of the given testing data.
      #
      # :call-seq:
      #   predict(x, y) -> Float
      #
      # * *Arguments* :
      #   - +x+ (NMatrix, shape: [n_samples, n_features]) -- Testing data.
      #   - +y+ (NMatrix, shape: [1, n_samples]) -- True labels for testing data.
      # * *Returns* :
      #   - Mean accuracy
      def score(x, y)
        p = predict(x)
        n_hits = (y.to_flat_a.map.with_index { |l, n| l == p[n] ? 1 : 0 }).inject(:+)
        n_hits / y.size.to_f
      end

      # Serializes object through Marshal#dump.
      def marshal_dump # :nodoc:
        { params: params,
          classes: @classes,
          estimators: @estimators.map { |e| Marshal.dump(e) } }
      end

      # Deserialize object through Marshal#load.
      def marshal_load(obj) # :nodoc:
        self.params = obj[:params]
        @classes = obj[:classes]
        @estimators = obj[:estimators].map { |e| Marshal.load(e) }
        nil
      end
    end
  end
end