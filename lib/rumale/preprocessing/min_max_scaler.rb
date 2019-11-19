# frozen_string_literal: true

require 'rumale/base/base_estimator'
require 'rumale/base/transformer'

module Rumale
  # This module consists of the classes that perform preprocessings.
  module Preprocessing
    # Normalize samples by scaling each feature to a given range.
    #
    # @example
    #   normalizer = Rumale::Preprocessing::MinMaxScaler.new(feature_range: [0.0, 1.0])
    #   new_training_samples = normalizer.fit_transform(training_samples)
    #   new_testing_samples = normalizer.transform(testing_samples)
    class MinMaxScaler
      include Base::BaseEstimator
      include Base::Transformer

      # Return the vector consists of the minimum value for each feature.
      # @return [Xumo::DFloat] (shape: [n_features])
      attr_reader :min_vec

      # Return the vector consists of the maximum value for each feature.
      # @return [Xumo::DFloat] (shape: [n_features])
      attr_reader :max_vec

      # Creates a new normalizer for scaling each feature to a given range.
      #
      # @param feature_range [Array<Float>] The desired range of samples.
      def initialize(feature_range: [0.0, 1.0])
        check_params_type(Array, feature_range: feature_range)
        @params = {}
        @params[:feature_range] = feature_range
        @min_vec = nil
        @max_vec = nil
      end

      # Calculate the minimum and maximum value of each feature for scaling.
      #
      # @overload fit(x) -> MinMaxScaler
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to calculate the minimum and maximum values.
      # @return [MinMaxScaler]
      def fit(x, _y = nil)
        x = check_convert_sample_array(x)
        @min_vec = x.min(0)
        @max_vec = x.max(0)
        self
      end

      # Calculate the minimum and maximum values, and then normalize samples to feature_range.
      #
      # @overload fit_transform(x) -> Xumo::DFloat
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to calculate the minimum and maximum values.
      # @return [Xumo::DFloat] The scaled samples.
      def fit_transform(x, _y = nil)
        x = check_convert_sample_array(x)
        fit(x).transform(x)
      end

      # Perform scaling the given samples according to feature_range.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to be scaled.
      # @return [Xumo::DFloat] The scaled samples.
      def transform(x)
        x = check_convert_sample_array(x)
        n_samples, = x.shape
        dif_vec = @max_vec - @min_vec
        dif_vec[dif_vec.eq(0)] = 1.0
        nx = (x - @min_vec.tile(n_samples, 1)) / dif_vec.tile(n_samples, 1)
        nx * (@params[:feature_range][1] - @params[:feature_range][0]) + @params[:feature_range][0]
      end

      # Dump marshal data.
      # @return [Hash] The marshal data about MinMaxScaler.
      def marshal_dump
        { params: @params,
          min_vec: @min_vec,
          max_vec: @max_vec }
      end

      # Load marshal data.
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @min_vec = obj[:min_vec]
        @max_vec = obj[:max_vec]
        nil
      end
    end
  end
end
