# frozen_string_literal: true

require 'rumale/base/base_estimator'
require 'rumale/base/classifier'

module Rumale
  # This module consists of the classes that implement naive bayes models.
  module NaiveBayes
    # BaseNaiveBayes is a class that has methods for common processes of naive bayes classifier.
    class BaseNaiveBayes
      include Base::BaseEstimator
      include Base::Classifier

      # Predict class labels for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to predict the labels.
      # @return [Xumo::Int32] (shape: [n_samples]) Predicted class label per sample.
      def predict(x)
        x = check_convert_sample_array(x)
        n_samples = x.shape.first
        decision_values = decision_function(x)
        Xumo::Int32.asarray(Array.new(n_samples) { |n| @classes[decision_values[n, true].max_index.to_i] })
      end

      # Predict log-probability for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to predict the log-probailities.
      # @return [Xumo::DFloat] (shape: [n_samples, n_classes]) Predicted log-probability of each class per sample.
      def predict_log_proba(x)
        x = check_convert_sample_array(x)
        n_samples, = x.shape
        log_likelihoods = decision_function(x)
        log_likelihoods - Xumo::NMath.log(Xumo::NMath.exp(log_likelihoods).sum(1)).reshape(n_samples, 1)
      end

      # Predict probability for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to predict the probailities.
      # @return [Xumo::DFloat] (shape: [n_samples, n_classes]) Predicted probability of each class per sample.
      def predict_proba(x)
        x = check_convert_sample_array(x)
        Xumo::NMath.exp(predict_log_proba(x)).abs
      end
    end

    # GaussianNB is a class that implements Gaussian Naive Bayes classifier.
    #
    # @example
    #   estimator = Rumale::NaiveBayes::GaussianNB.new
    #   estimator.fit(training_samples, training_labels)
    #   results = estimator.predict(testing_samples)
    class GaussianNB < BaseNaiveBayes
      # Return the class labels.
      # @return [Xumo::Int32] (size: n_classes)
      attr_reader :classes

      # Return the prior probabilities of the classes.
      # @return [Xumo::DFloat] (shape: [n_classes])
      attr_reader :class_priors

      # Return the mean vectors of the classes.
      # @return [Xumo::DFloat] (shape: [n_classes, n_features])
      attr_reader :means

      # Return the variance vectors of the classes.
      # @return [Xumo::DFloat] (shape: [n_classes, n_features])
      attr_reader :variances

      # Create a new classifier with Gaussian Naive Bayes.
      def initialize
        @params = {}
      end

      # Fit the model with given training data.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @param y [Xumo::Int32] (shape: [n_samples]) The categorical variables (e.g. labels)
      #   to be used for fitting the model.
      # @return [GaussianNB] The learned classifier itself.
      def fit(x, y)
        x = check_convert_sample_array(x)
        y = check_convert_label_array(y)
        check_sample_label_size(x, y)
        n_samples, = x.shape
        @classes = Xumo::Int32[*y.to_a.uniq.sort]
        @class_priors = Xumo::DFloat[*@classes.to_a.map { |l| y.eq(l).count / n_samples.to_f }]
        @means = Xumo::DFloat[*@classes.to_a.map { |l| x[y.eq(l).where, true].mean(0) }]
        @variances = Xumo::DFloat[*@classes.to_a.map { |l| x[y.eq(l).where, true].var(0) }]
        self
      end

      # Calculate confidence scores for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to compute the scores.
      # @return [Xumo::DFloat] (shape: [n_samples, n_classes]) Confidence scores per sample for each class.
      def decision_function(x)
        x = check_convert_sample_array(x)
        n_classes = @classes.size
        log_likelihoods = Array.new(n_classes) do |l|
          Math.log(@class_priors[l]) - 0.5 * (
            Xumo::NMath.log(2.0 * Math::PI * @variances[l, true]) +
            ((x - @means[l, true])**2 / @variances[l, true])).sum(1)
        end
        Xumo::DFloat[*log_likelihoods].transpose
      end

      # Dump marshal data.
      #
      # @return [Hash] The marshal data about GaussianNB.
      def marshal_dump
        { params: @params,
          classes: @classes,
          class_priors: @class_priors,
          means: @means,
          variances: @variances }
      end

      # Load marshal data.
      #
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @classes = obj[:classes]
        @class_priors = obj[:class_priors]
        @means = obj[:means]
        @variances = obj[:variances]
        nil
      end
    end

    # MultinomialNB is a class that implements Multinomial Naive Bayes classifier.
    #
    # @example
    #   estimator = Rumale::NaiveBayes::MultinomialNB.new(smoothing_param: 1.0)
    #   estimator.fit(training_samples, training_labels)
    #   results = estimator.predict(testing_samples)
    #
    # *Reference*
    # - C D. Manning, P. Raghavan, and H. Schutze, "Introduction to Information Retrieval," Cambridge University Press., 2008.
    class MultinomialNB < BaseNaiveBayes
      # Return the class labels.
      # @return [Xumo::Int32] (size: n_classes)
      attr_reader :classes

      # Return the prior probabilities of the classes.
      # @return [Xumo::DFloat] (shape: [n_classes])
      attr_reader :class_priors

      # Return the conditional probabilities for features of each class.
      # @return [Xumo::DFloat] (shape: [n_classes, n_features])
      attr_reader :feature_probs

      # Create a new classifier with Multinomial Naive Bayes.
      #
      # @param smoothing_param [Float] The Laplace smoothing parameter.
      def initialize(smoothing_param: 1.0)
        check_params_numeric(smoothing_param: smoothing_param)
        check_params_positive(smoothing_param: smoothing_param)
        @params = {}
        @params[:smoothing_param] = smoothing_param
      end

      # Fit the model with given training data.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @param y [Xumo::Int32] (shape: [n_samples]) The categorical variables (e.g. labels)
      #   to be used for fitting the model.
      # @return [MultinomialNB] The learned classifier itself.
      def fit(x, y)
        x = check_convert_sample_array(x)
        y = check_convert_label_array(y)
        check_sample_label_size(x, y)
        n_samples, = x.shape
        @classes = Xumo::Int32[*y.to_a.uniq.sort]
        @class_priors = Xumo::DFloat[*@classes.to_a.map { |l| y.eq(l).count / n_samples.to_f }]
        count_features = Xumo::DFloat[*@classes.to_a.map { |l| x[y.eq(l).where, true].sum(0) }]
        count_features += @params[:smoothing_param]
        n_classes = @classes.size
        @feature_probs = count_features / count_features.sum(1).reshape(n_classes, 1)
        self
      end

      # Calculate confidence scores for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to compute the scores.
      # @return [Xumo::DFloat] (shape: [n_samples, n_classes]) Confidence scores per sample for each class.
      def decision_function(x)
        x = check_convert_sample_array(x)
        n_classes = @classes.size
        bin_x = x.gt(0)
        log_likelihoods = Array.new(n_classes) do |l|
          Math.log(@class_priors[l]) + (Xumo::DFloat[*bin_x] * Xumo::NMath.log(@feature_probs[l, true])).sum(1)
        end
        Xumo::DFloat[*log_likelihoods].transpose
      end

      # Dump marshal data.
      #
      # @return [Hash] The marshal data about MultinomialNB.
      def marshal_dump
        { params: @params,
          classes: @classes,
          class_priors: @class_priors,
          feature_probs: @feature_probs }
      end

      # Load marshal data.
      #
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @classes = obj[:classes]
        @class_priors = obj[:class_priors]
        @feature_probs = obj[:feature_probs]
        nil
      end
    end

    # BernoulliNB is a class that implements Bernoulli Naive Bayes classifier.
    #
    # @example
    #   estimator = Rumale::NaiveBayes::BernoulliNB.new(smoothing_param: 1.0, bin_threshold: 0.0)
    #   estimator.fit(training_samples, training_labels)
    #   results = estimator.predict(testing_samples)
    #
    # *Reference*
    # - C D. Manning, P. Raghavan, and H. Schutze, "Introduction to Information Retrieval," Cambridge University Press., 2008.
    class BernoulliNB < BaseNaiveBayes
      # Return the class labels.
      # @return [Xumo::Int32] (size: n_classes)
      attr_reader :classes

      # Return the prior probabilities of the classes.
      # @return [Xumo::DFloat] (shape: [n_classes])
      attr_reader :class_priors

      # Return the conditional probabilities for features of each class.
      # @return [Xumo::DFloat] (shape: [n_classes, n_features])
      attr_reader :feature_probs

      # Create a new classifier with Bernoulli Naive Bayes.
      #
      # @param smoothing_param [Float] The Laplace smoothing parameter.
      # @param bin_threshold [Float] The threshold for binarizing of features.
      def initialize(smoothing_param: 1.0, bin_threshold: 0.0)
        check_params_numeric(smoothing_param: smoothing_param, bin_threshold: bin_threshold)
        check_params_positive(smoothing_param: smoothing_param)
        @params = {}
        @params[:smoothing_param] = smoothing_param
        @params[:bin_threshold] = bin_threshold
      end

      # Fit the model with given training data.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @param y [Xumo::Int32] (shape: [n_samples]) The categorical variables (e.g. labels)
      #   to be used for fitting the model.
      # @return [BernoulliNB] The learned classifier itself.
      def fit(x, y)
        x = check_convert_sample_array(x)
        y = check_convert_label_array(y)
        check_sample_label_size(x, y)
        n_samples, = x.shape
        bin_x = Xumo::DFloat[*x.gt(@params[:bin_threshold])]
        @classes = Xumo::Int32[*y.to_a.uniq.sort]
        n_samples_each_class = Xumo::DFloat[*@classes.to_a.map { |l| y.eq(l).count.to_f }]
        @class_priors = n_samples_each_class / n_samples
        count_features = Xumo::DFloat[*@classes.to_a.map { |l| bin_x[y.eq(l).where, true].sum(0) }]
        count_features += @params[:smoothing_param]
        n_samples_each_class += 2.0 * @params[:smoothing_param]
        n_classes = @classes.size
        @feature_probs = count_features / n_samples_each_class.reshape(n_classes, 1)
        self
      end

      # Calculate confidence scores for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to compute the scores.
      # @return [Xumo::DFloat] (shape: [n_samples, n_classes]) Confidence scores per sample for each class.
      def decision_function(x)
        x = check_convert_sample_array(x)
        n_classes = @classes.size
        bin_x = Xumo::DFloat[*x.gt(@params[:bin_threshold])]
        not_bin_x = Xumo::DFloat[*x.le(@params[:bin_threshold])]
        log_likelihoods = Array.new(n_classes) do |l|
          Math.log(@class_priors[l]) + (
            (Xumo::DFloat[*bin_x] * Xumo::NMath.log(@feature_probs[l, true])).sum(1)
            (Xumo::DFloat[*not_bin_x] * Xumo::NMath.log(1.0 - @feature_probs[l, true])).sum(1))
        end
        Xumo::DFloat[*log_likelihoods].transpose
      end

      # Dump marshal data.
      #
      # @return [Hash] The marshal data about BernoulliNB.
      def marshal_dump
        { params: @params,
          classes: @classes,
          class_priors: @class_priors,
          feature_probs: @feature_probs }
      end

      # Load marshal data.
      #
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @classes = obj[:classes]
        @class_priors = obj[:class_priors]
        @feature_probs = obj[:feature_probs]
        nil
      end
    end
  end
end
