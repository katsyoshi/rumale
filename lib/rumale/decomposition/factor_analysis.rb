# frozen_string_literal: true

require 'rumale/base/base_estimator'
require 'rumale/base/transformer'
require 'rumale/utils'

module Rumale
  module Decomposition
    # FactorAnalysis is a class that implements fator analysis with EM algorithm.
    #
    # @example
    #   require 'numo/linalg/autoloader'
    #   decomposer = Rumale::Decomposition::FactorAnalysis.new(n_components: 2)
    #   representaion = decomposer.fit_transform(samples)
    #
    # *Reference*
    # - D. Barber, "Bayesian Reasoning and Machine Learning," Cambridge University Press, 2012.
    class FactorAnalysis
      include Base::BaseEstimator
      include Base::Transformer

      # Returns the mean vector.
      # @return [Xumo::DFloat] (shape: [n_features])
      attr_reader :mean

      # Returns the estimated noise variance for each feature.
      # @return [Xumo::DFloat] (shape: [n_features])
      attr_reader :noise_variance

      # Returns the components with maximum variance.
      # @return [Xumo::DFloat] (shape: [n_components, n_features])
      attr_reader :components

      # Returns the log likelihood at each iteration.
      # @return [Xumo::DFloat] (shape: [n_iter])
      attr_reader :loglike

      # Return the number of iterations run for optimization
      # @return [Integer]
      attr_reader :n_iter

      # Create a new transformer with factor analysis.
      #
      # @param n_components [Integer] The number of components (dimensionality of latent space).
      # @param max_iter [Integer] The maximum number of iterations.
      # @param tol [Float/Nil] The tolerance of termination criterion for EM algorithm.
      #   If nil is given, iterate EM steps up to the maximum number of iterations.
      def initialize(n_components: 2, max_iter: 100, tol: 1e-8)
        check_params_numeric(n_components: n_components, max_iter: max_iter)
        check_params_numeric_or_nil(tol: tol)
        check_params_positive(n_components: n_components, max_iter: max_iter)
        @params = {}
        @params[:n_components] = n_components
        @params[:max_iter] = max_iter
        @params[:tol] = tol
        @mean = nil
        @noise_variance = nil
        @components = nil
        @loglike = nil
        @n_iter = nil
      end

      # Fit the model with given training data.
      #
      # @overload fit(x) -> FactorAnalysis
      #   @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @return [FactorAnalysis] The learned transformer itself.
      def fit(x, _y = nil)
        raise 'FactorAnalysis#fit requires Xumo::Linalg but that is not loaded.' unless enable_linalg?

        # initialize some variables.
        n_samples, n_features = x.shape
        @mean = x.mean(0)
        centered_x = x - @mean
        cov_mat = centered_x.transpose.dot(centered_x) / n_samples
        sample_vars = x.var(0)
        sqrt_n_samples = Math.sqrt(n_samples)
        @noise_variance = Xumo::DFloat.ones(n_features)

        # run optimization.
        old_loglike = 0.0
        @n_iter = 0
        @loglike = [] unless @params[:tol].nil?
        @params[:max_iter].times do |t|
          @n_iter = t + 1
          sqrt_noise_variance = Xumo::NMath.sqrt(@noise_variance)
          scaled_x = centered_x / (sqrt_noise_variance * sqrt_n_samples + 1e-12)
          s, u = truncate_svd(scaled_x, @params[:n_components])
          scaler = Xumo::NMath.sqrt(Xumo::DFloat.maximum(s**2 - 1.0, 0.0))
          @components = (sqrt_noise_variance.diag.dot(u) * scaler).transpose.dup
          @noise_variance = Xumo::DFloat.maximum(sample_vars - @components.transpose.dot(@components).diagonal, 1e-12)
          next if @params[:tol].nil?
          new_loglike = log_likelihood(cov_mat, @components, @noise_variance)
          @loglike.push(new_loglike)
          break if (old_loglike - new_loglike).abs <= @params[:tol]
          old_loglike = new_loglike
        end

        @loglike = Xumo::DFloat.cast(@loglike) unless @params[:tol].nil?
        @components = @components[0, true].dup if @params[:n_components] == 1
        self
      end

      # Fit the model with training data, and then transform them with the learned model.
      #
      # @overload fit_transform(x) -> Xumo::DFloat
      #   @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @return [Xumo::DFloat] (shape: [n_samples, n_components]) The transformed data
      def fit_transform(x, _y = nil)
        x = check_convert_sample_array(x)
        raise 'FactorAnalysis#fit_transform requires Xumo::Linalg but that is not loaded.' unless enable_linalg?

        fit(x).transform(x)
      end

      # Transform the given data with the learned model.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The data to be transformed with the learned model.
      # @return [Xumo::DFloat] (shape: [n_samples, n_components]) The transformed data.
      def transform(x)
        x = check_convert_sample_array(x)
        raise 'FactorAnalysis#transform requires Xumo::Linalg but that is not loaded.' unless enable_linalg?

        factors = @params[:n_components] == 1 ? @components.expand_dims(0) : @components
        centered_x = x - @mean
        beta = Xumo::Linalg.inv(Xumo::DFloat.eye(factors.shape[0]) + (factors / @noise_variance).dot(factors.transpose))
        z = centered_x.dot((beta.dot(factors) / @noise_variance).transpose)
        @params[:n_components] == 1 ? z[true, 0].dup : z
      end

      # Dump marshal data.
      # @return [Hash] The marshal data.
      def marshal_dump
        { params: @params,
          mean: @mean,
          noise_variance: @noise_variance,
          components: @components,
          loglike: @loglike,
          n_iter: @n_iter }
      end

      # Load marshal data.
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @mean = obj[:mean]
        @noise_variance = obj[:noise_variance]
        @components = obj[:components]
        @loglike = obj[:loglike]
        @n_iter = obj[:n_iter]
      end

      private

      def log_likelihood(cov_mat, factors, noise_vars)
        n_samples = noise_vars.size
        fact_cov_mat = factors.transpose.dot(factors) + noise_vars.diag
        n_samples.fdiv(2) * Math.log(Xumo::Linalg.det(fact_cov_mat)) + Xumo::Linalg.inv(fact_cov_mat).dot(cov_mat).trace
      end

      def truncate_svd(x, k)
        m = x.shape[1]
        eig_vals, eig_vecs = Xumo::Linalg.eigh(x.transpose.dot(x), vals_range: (m - k)...m)
        s = Xumo::NMath.sqrt(eig_vals.reverse.dup)
        u = eig_vecs.reverse(1).dup
        [s, u]
      end
    end
  end
end
