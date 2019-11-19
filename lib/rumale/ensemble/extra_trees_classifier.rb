# frozen_string_literal: true

require 'rumale/tree/extra_tree_classifier'
require 'rumale/ensemble/random_forest_classifier'

module Rumale
  module Ensemble
    # ExtraTreesClassifier is a class that implements extremely randomized trees for classification.
    # The algorithm of extremely randomized trees is similar to random forest.
    # The features of the algorithm of extremely randomized trees are
    # not to apply the bagging procedure and to randomly select the threshold for splitting feature space.
    #
    # @example
    #   estimator =
    #     Rumale::Ensemble::ExtraTreesClassifier.new(
    #       n_estimators: 10, criterion: 'gini', max_depth: 3, max_leaf_nodes: 10, min_samples_leaf: 5, random_seed: 1)
    #   estimator.fit(training_samples, traininig_labels)
    #   results = estimator.predict(testing_samples)
    #
    # *Reference*
    # - P. Geurts, D. Ernst, and L. Wehenkel, "Extremely randomized trees," Machine Learning, vol. 63 (1), pp. 3--42, 2006.
    class ExtraTreesClassifier < RandomForestClassifier
      # Return the set of estimators.
      # @return [Array<ExtraTreeClassifier>]
      attr_reader :estimators

      # Return the class labels.
      # @return [Xumo::Int32] (size: n_classes)
      attr_reader :classes

      # Return the importance for each feature.
      # @return [Xumo::DFloat] (size: n_features)
      attr_reader :feature_importances

      # Return the random generator for random selection of feature index.
      # @return [Random]
      attr_reader :rng

      # Create a new classifier with extremely randomized trees.
      #
      # @param n_estimators [Integer] The numeber of trees for contructing extremely randomized trees.
      # @param criterion [String] The function to evalue spliting point. Supported criteria are 'gini' and 'entropy'.
      # @param max_depth [Integer] The maximum depth of the tree.
      #   If nil is given, extra tree grows without concern for depth.
      # @param max_leaf_nodes [Integer] The maximum number of leaves on extra tree.
      #   If nil is given, number of leaves is not limited.
      # @param min_samples_leaf [Integer] The minimum number of samples at a leaf node.
      # @param max_features [Integer] The number of features to consider when searching optimal split point.
      #   If nil is given, split process considers all features.
      # @param random_seed [Integer] The seed value using to initialize the random generator.
      #   It is used to randomly determine the order of features when deciding spliting point.
      def initialize(n_estimators: 10,
                     criterion: 'gini', max_depth: nil, max_leaf_nodes: nil, min_samples_leaf: 1,
                     max_features: nil, n_jobs: nil, random_seed: nil)
        check_params_numeric_or_nil(max_depth: max_depth, max_leaf_nodes: max_leaf_nodes,
                                    max_features: max_features, n_jobs: n_jobs, random_seed: random_seed)
        check_params_numeric(n_estimators: n_estimators, min_samples_leaf: min_samples_leaf)
        check_params_string(criterion: criterion)
        check_params_positive(n_estimators: n_estimators, max_depth: max_depth,
                              max_leaf_nodes: max_leaf_nodes, min_samples_leaf: min_samples_leaf,
                              max_features: max_features)
        super
      end

      # Fit the model with given training data.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @param y [Xumo::Int32] (shape: [n_samples]) The labels to be used for fitting the model.
      # @return [ExtraTreesClassifier] The learned classifier itself.
      def fit(x, y)
        x = check_convert_sample_array(x)
        y = check_convert_label_array(y)
        check_sample_label_size(x, y)
        # Initialize some variables.
        n_features = x.shape[1]
        @params[:max_features] = Math.sqrt(n_features).to_i unless @params[:max_features].is_a?(Integer)
        @params[:max_features] = [[1, @params[:max_features]].max, n_features].min
        @classes = Xumo::Int32.asarray(y.to_a.uniq.sort)
        @feature_importances = Xumo::DFloat.zeros(n_features)
        # Construct trees.
        @estimators = Array.new(@params[:n_estimators]) do
          tree = Tree::ExtraTreeClassifier.new(
            criterion: @params[:criterion], max_depth: @params[:max_depth],
            max_leaf_nodes: @params[:max_leaf_nodes], min_samples_leaf: @params[:min_samples_leaf],
            max_features: @params[:max_features], random_seed: @rng.rand(Rumale::Values.int_max)
          )
          tree.fit(x, y)
          @feature_importances += tree.feature_importances
          tree
        end
        @feature_importances /= @feature_importances.sum
        self
      end

      # Predict class labels for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to predict the labels.
      # @return [Xumo::Int32] (shape: [n_samples]) Predicted class label per sample.
      def predict(x)
        x = check_convert_sample_array(x)
        super
      end

      # Predict probability for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to predict the probailities.
      # @return [Xumo::DFloat] (shape: [n_samples, n_classes]) Predicted probability of each class per sample.
      def predict_proba(x)
        x = check_convert_sample_array(x)
        super
      end

      # Return the index of the leaf that each sample reached.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to predict the labels.
      # @return [Xumo::Int32] (shape: [n_samples, n_estimators]) Leaf index for sample.
      def apply(x)
        x = check_convert_sample_array(x)
        super
      end

      # Dump marshal data.
      # @return [Hash] The marshal data about ExtraTreesClassifier.
      def marshal_dump
        super
      end

      # Load marshal data.
      # @return [nil]
      def marshal_load(obj)
        super
      end
    end
  end
end
