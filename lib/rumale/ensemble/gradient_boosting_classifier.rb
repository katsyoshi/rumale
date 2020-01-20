# frozen_string_literal: true

require 'rumale/values'
require 'rumale/base/base_estimator'
require 'rumale/base/classifier'
require 'rumale/tree/gradient_tree_regressor'

module Rumale
  module Ensemble
    # GradientBoostingClassifier is a class that implements gradient tree boosting for classification.
    # The class use negative binomial log-likelihood for the loss function.
    # For multiclass classification problem, it uses one-vs-the-rest strategy.
    #
    # @example
    #   estimator =
    #     Rumale::Ensemble::GradientBoostingClassifier.new(
    #       n_estimators: 100, learning_rate: 0.3, reg_lambda: 0.001, random_seed: 1)
    #   estimator.fit(training_samples, traininig_values)
    #   results = estimator.predict(testing_samples)
    #
    # *reference*
    # - J H. Friedman, "Greedy Function Approximation: A Gradient Boosting Machine," Annals of Statistics, 29 (5), pp. 1189--1232, 2001.
    # - J H. Friedman, "Stochastic Gradient Boosting," Computational Statistics and Data Analysis, 38 (4), pp. 367--378, 2002.
    # - T. Chen and C. Guestrin, "XGBoost: A Scalable Tree Boosting System,"  Proc. KDD'16, pp. 785--794, 2016.
    #
    class GradientBoostingClassifier
      include Base::BaseEstimator
      include Base::Classifier

      # Return the set of estimators.
      # @return [Array<GradientTreeRegressor>] or [Array<Array<GradientTreeRegressor>>]
      attr_reader :estimators

      # Return the class labels.
      # @return [Xumo::Int32] (size: n_classes)
      attr_reader :classes

      # Return the importance for each feature.
      # The feature importances are calculated based on the numbers of times the feature is used for splitting.
      # @return [Xumo::DFloat] (size: n_features)
      attr_reader :feature_importances

      # Return the random generator for random selection of feature index.
      # @return [Random]
      attr_reader :rng

      # Create a new classifier with gradient tree boosting.
      #
      # @param n_estimators [Integer] The numeber of trees for contructing classifier.
      # @param learning_rate [Float] The boosting learining rate
      # @param reg_lambda [Float] The L2 regularization term on weight.
      # @param subsample [Float] The subsampling ratio of the training samples.
      # @param max_depth [Integer] The maximum depth of the tree.
      #   If nil is given, decision tree grows without concern for depth.
      # @param max_leaf_nodes [Integer] The maximum number of leaves on decision tree.
      #   If nil is given, number of leaves is not limited.
      # @param min_samples_leaf [Integer] The minimum number of samples at a leaf node.
      # @param max_features [Integer] The number of features to consider when searching optimal split point.
      #   If nil is given, split process considers all features.
      # @param n_jobs [Integer] The number of jobs for running the fit and predict methods in parallel.
      #   If nil is given, the methods do not execute in parallel.
      #   If zero or less is given, it becomes equal to the number of processors.
      #   This parameter is ignored if the Parallel gem is not loaded.
      # @param random_seed [Integer] The seed value using to initialize the random generator.
      #   It is used to randomly determine the order of features when deciding spliting point.
      def initialize(n_estimators: 100, learning_rate: 0.1, reg_lambda: 0.0, subsample: 1.0,
                     max_depth: nil, max_leaf_nodes: nil, min_samples_leaf: 1,
                     max_features: nil, n_jobs: nil, random_seed: nil)
        check_params_type_or_nil(Integer, max_depth: max_depth, max_leaf_nodes: max_leaf_nodes,
                                          max_features: max_features, n_jobs: n_jobs, random_seed: random_seed)
        check_params_numeric(n_estimators: n_estimators, min_samples_leaf: min_samples_leaf,
                             learning_rate: learning_rate, reg_lambda: reg_lambda, subsample: subsample)
        check_params_positive(n_estimators: n_estimators, learning_rate: learning_rate, reg_lambda: reg_lambda,
                              subsample: subsample, max_depth: max_depth, max_leaf_nodes: max_leaf_nodes,
                              min_samples_leaf: min_samples_leaf, max_features: max_features)
        @params = {}
        @params[:n_estimators] = n_estimators
        @params[:learning_rate] = learning_rate
        @params[:reg_lambda] = reg_lambda
        @params[:subsample] = subsample
        @params[:max_depth] = max_depth
        @params[:max_leaf_nodes] = max_leaf_nodes
        @params[:min_samples_leaf] = min_samples_leaf
        @params[:max_features] = max_features
        @params[:n_jobs] = n_jobs
        @params[:random_seed] = random_seed
        @params[:random_seed] ||= srand
        @estimators = nil
        @classes = nil
        @base_predictions = nil
        @feature_importances = nil
        @rng = Random.new(@params[:random_seed])
      end

      # Fit the model with given training data.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @param y [Xumo::Int32] (shape: [n_samples]) The labels to be used for fitting the model.
      # @return [GradientBoostingClassifier] The learned classifier itself.
      def fit(x, y)
        x = check_convert_sample_array(x)
        y = check_convert_label_array(y)
        check_sample_label_size(x, y)
        # initialize some variables.
        n_features = x.shape[1]
        @params[:max_features] = n_features if @params[:max_features].nil?
        @params[:max_features] = [[1, @params[:max_features]].max, n_features].min
        @classes = Xumo::Int32[*y.to_a.uniq.sort]
        n_classes = @classes.size
        # train estimator.
        if n_classes > 2
          @base_predictions = multiclass_base_predictions(y)
          @estimators = multiclass_estimators(x, y)
        else
          negative_label = y.to_a.uniq.min
          bin_y = Xumo::DFloat.cast(y.ne(negative_label)) * 2 - 1
          y_mean = bin_y.mean
          @base_predictions = 0.5 * Xumo::NMath.log((1.0 + y_mean) / (1.0 - y_mean))
          @estimators = partial_fit(x, bin_y, @base_predictions)
        end
        # calculate feature importances.
        @feature_importances = if n_classes > 2
                                 multiclass_feature_importances
                               else
                                 @estimators.map(&:feature_importances).reduce(&:+)
                               end
        self
      end

      # Calculate confidence scores for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to compute the scores.
      # @return [Xumo::DFloat] (shape: [n_samples, n_classes]) Confidence score per sample.
      def decision_function(x)
        x = check_convert_sample_array(x)
        n_classes = @classes.size
        if n_classes > 2
          multiclass_scores(x)
        else
          @estimators.map { |tree| tree.predict(x) }.reduce(&:+) + @base_predictions
        end
      end

      # Predict class labels for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to predict the labels.
      # @return [Xumo::Int32] (shape: [n_samples]) Predicted class label per sample.
      def predict(x)
        x = check_convert_sample_array(x)
        n_samples = x.shape[0]
        probs = predict_proba(x)
        Xumo::Int32.asarray(Array.new(n_samples) { |n| @classes[probs[n, true].max_index] })
      end

      # Predict probability for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to predict the probailities.
      # @return [Xumo::DFloat] (shape: [n_samples, n_classes]) Predicted probability of each class per sample.
      def predict_proba(x)
        x = check_convert_sample_array(x)

        proba = 1.0 / (Xumo::NMath.exp(-decision_function(x)) + 1.0)

        return (proba.transpose / proba.sum(axis: 1)).transpose if @classes.size > 2

        n_samples, = x.shape
        probs = Xumo::DFloat.zeros(n_samples, 2)
        probs[true, 1] = proba
        probs[true, 0] = 1.0 - proba
        probs
      end

      # Return the index of the leaf that each sample reached.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to predict the labels.
      # @return [Xumo::Int32] (shape: [n_samples, n_estimators, n_classes]) Leaf index for sample.
      def apply(x)
        x = check_convert_sample_array(x)
        n_classes = @classes.size
        leaf_ids = if n_classes > 2
                     Array.new(n_classes) { |n| @estimators[n].map { |tree| tree.apply(x) } }
                   else
                     @estimators.map { |tree| tree.apply(x) }
                   end
        Xumo::Int32[*leaf_ids].transpose
      end

      # Dump marshal data.
      # @return [Hash] The marshal data about GradientBoostingClassifier.
      def marshal_dump
        { params: @params,
          estimators: @estimators,
          classes: @classes,
          base_predictions: @base_predictions,
          feature_importances: @feature_importances,
          rng: @rng }
      end

      # Load marshal data.
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @estimators = obj[:estimators]
        @classes = obj[:classes]
        @base_predictions = obj[:base_predictions]
        @feature_importances = obj[:feature_importances]
        @rng = obj[:rng]
        nil
      end

      private

      def partial_fit(x, y, init_pred)
        # initialize some variables.
        estimators = []
        n_samples = x.shape[0]
        n_sub_samples = [n_samples, [(n_samples * @params[:subsample]).to_i, 1].max].min
        whole_ids = Array.new(n_samples) { |v| v }
        y_pred = Xumo::DFloat.ones(n_samples) * init_pred
        sub_rng = @rng.dup
        # grow trees.
        @params[:n_estimators].times do |_t|
          # subsampling
          ids = whole_ids.sample(n_sub_samples, random: sub_rng)
          x_sub = x[ids, true]
          y_sub = y[ids]
          y_pred_sub = y_pred[ids]
          # train tree
          g = gradient(y_sub, y_pred_sub)
          h = hessian(y_sub, y_pred_sub)
          tree = plant_tree(sub_rng)
          tree.fit(x_sub, y_sub, g, h)
          estimators.push(tree)
          # update
          y_pred += tree.predict(x)
        end
        estimators
      end

      # for debug
      #
      # def loss(y_true, y_pred)
      #   # y_true in {-1, 1}
      #   Xumo::NMath.log(1.0 + Xumo::NMath.exp(-2.0 * y_true * y_pred)).mean
      # end

      def gradient(y_true, y_pred)
        # y in {-1, 1}
        -2.0 * y_true / (1.0 + Xumo::NMath.exp(2.0 * y_true * y_pred))
      end

      def hessian(y_true, y_pred)
        abs_response = gradient(y_true, y_pred).abs
        abs_response * (2.0 - abs_response)
      end

      def plant_tree(sub_rng)
        Rumale::Tree::GradientTreeRegressor.new(
          reg_lambda: @params[:reg_lambda], shrinkage_rate: @params[:learning_rate],
          max_depth: @params[:max_depth],
          max_leaf_nodes: @params[:max_leaf_nodes], min_samples_leaf: @params[:min_samples_leaf],
          max_features: @params[:max_features], random_seed: sub_rng.rand(Rumale::Values.int_max)
        )
      end

      def multiclass_base_predictions(y)
        n_classes = @classes.size
        b = if enable_parallel?
              # :nocov:
              parallel_map(n_classes) do |n|
                bin_y = Xumo::DFloat.cast(y.eq(@classes[n])) * 2 - 1
                y_mean = bin_y.mean
                0.5 * Math.log((1.0 + y_mean) / (1.0 - y_mean))
              end
              # :nocov:
            else
              Array.new(n_classes) do |n|
                bin_y = Xumo::DFloat.cast(y.eq(@classes[n])) * 2 - 1
                y_mean = bin_y.mean
                0.5 * Math.log((1.0 + y_mean) / (1.0 - y_mean))
              end
            end
        Xumo::DFloat.asarray(b)
      end

      def multiclass_estimators(x, y)
        n_classes = @classes.size
        if enable_parallel?
          # :nocov:
          parallel_map(n_classes) do |n|
            bin_y = Xumo::DFloat.cast(y.eq(@classes[n])) * 2 - 1
            partial_fit(x, bin_y, @base_predictions[n])
          end
          # :nocov:
        else
          Array.new(n_classes) do |n|
            bin_y = Xumo::DFloat.cast(y.eq(@classes[n])) * 2 - 1
            partial_fit(x, bin_y, @base_predictions[n])
          end
        end
      end

      def multiclass_feature_importances
        n_classes = @classes.size
        if enable_parallel?
          parallel_map(n_classes) { |n| @estimators[n].map(&:feature_importances).reduce(&:+) }.reduce(&:+)
        else
          Array.new(n_classes) { |n| @estimators[n].map(&:feature_importances).reduce(&:+) }.reduce(&:+)
        end
      end

      def multiclass_scores(x)
        n_classes = @classes.size
        s = if enable_parallel?
              # :nocov:
              parallel_map(n_classes) do |n|
                @estimators[n].map { |tree| tree.predict(x) }.reduce(&:+)
              end
              # :nocov:
            else
              Array.new(n_classes) do |n|
                @estimators[n].map { |tree| tree.predict(x) }.reduce(&:+)
              end
            end
        Xumo::DFloat.asarray(s).transpose + @base_predictions
      end
    end
  end
end
