# frozen_string_literal: true

require 'rumale/linear_model/base_sgd'
require 'rumale/base/regressor'

module Rumale
  module LinearModel
    # Lasso is a class that implements Lasso Regression
    # with stochastic gradient descent (SGD) optimization.
    #
    # @example
    #   estimator =
    #     Rumale::LinearModel::Lasso.new(reg_param: 0.1, max_iter: 500, batch_size: 20, random_seed: 1)
    #   estimator.fit(training_samples, traininig_values)
    #   results = estimator.predict(testing_samples)
    #
    # *Reference*
    # - S. Shalev-Shwartz and Y. Singer, "Pegasos: Primal Estimated sub-GrAdient SOlver for SVM," Proc. ICML'07, pp. 807--814, 2007.
    # - Y. Tsuruoka, J. Tsujii, and S. Ananiadou, "Stochastic Gradient Descent Training for L1-regularized Log-linear Models with Cumulative Penalty," Proc. ACL'09, pp. 477--485, 2009.
    # - L. Bottou, "Large-Scale Machine Learning with Stochastic Gradient Descent," Proc. COMPSTAT'10, pp. 177--186, 2010.
    class Lasso < BaseSGD
      include Base::Regressor

      # Return the weight vector.
      # @return [Xumo::DFloat] (shape: [n_outputs, n_features])
      attr_reader :weight_vec

      # Return the bias term (a.k.a. intercept).
      # @return [Xumo::DFloat] (shape: [n_outputs])
      attr_reader :bias_term

      # Return the random generator for random sampling.
      # @return [Random]
      attr_reader :rng

      # Create a new Lasso regressor.
      #
      # @param learning_rate [Float] The initial value of learning rate.
      #   The learning rate decreases as the iteration proceeds according to the equation: learning_rate / (1 + decay * t).
      # @param decay [Float] The smoothing parameter for decreasing learning rate as the iteration proceeds.
      #   If nil is given, the decay sets to 'reg_param * learning_rate'.
      # @param momentum [Float] The momentum factor.
      # @param reg_param [Float] The regularization parameter.
      # @param fit_bias [Boolean] The flag indicating whether to fit the bias term.
      # @param bias_scale [Float] The scale of the bias term.
      # @param max_iter [Integer] The maximum number of epochs that indicates
      #   how many times the whole data is given to the training process.
      # @param batch_size [Integer] The size of the mini batches.
      # @param tol [Float] The tolerance of loss for terminating optimization.
      # @param n_jobs [Integer] The number of jobs for running the fit method in parallel.
      #   If nil is given, the method does not execute in parallel.
      #   If zero or less is given, it becomes equal to the number of processors.
      #   This parameter is ignored if the Parallel gem is not loaded.
      # @param verbose [Boolean] The flag indicating whether to output loss during iteration.
      # @param random_seed [Integer] The seed value using to initialize the random generator.
      def initialize(learning_rate: 0.01, decay: nil, momentum: 0.9,
                     reg_param: 1.0, fit_bias: true, bias_scale: 1.0,
                     max_iter: 200, batch_size: 50, tol: 1e-4,
                     n_jobs: nil, verbose: false, random_seed: nil)
        check_params_numeric(learning_rate: learning_rate, momentum: momentum,
                             reg_param: reg_param, bias_scale: bias_scale,
                             max_iter: max_iter, batch_size: batch_size, tol: tol)
        check_params_boolean(fit_bias: fit_bias, verbose: verbose)
        check_params_numeric_or_nil(decay: decay, n_jobs: n_jobs, random_seed: random_seed)
        check_params_positive(learning_rate: learning_rate, reg_param: reg_param, max_iter: max_iter, batch_size: batch_size)
        super()
        @params.merge!(method(:initialize).parameters.map { |_t, arg| [arg, binding.local_variable_get(arg)] }.to_h)
        @params[:decay] ||= @params[:reg_param] * @params[:learning_rate]
        @params[:random_seed] ||= srand
        @rng = Random.new(@params[:random_seed])
        @penalty_type = L1_PENALTY
        @loss_func = LinearModel::Loss::MeanSquaredError.new
        @weight_vec = nil
        @bias_term = nil
      end

      # Fit the model with given training data.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @param y [Xumo::Int32] (shape: [n_samples, n_outputs]) The target values to be used for fitting the model.
      # @return [Lasso] The learned regressor itself.
      def fit(x, y)
        x = check_convert_sample_array(x)
        y = check_convert_tvalue_array(y)
        check_sample_tvalue_size(x, y)

        n_outputs = y.shape[1].nil? ? 1 : y.shape[1]
        n_features = x.shape[1]

        if n_outputs > 1
          @weight_vec = Xumo::DFloat.zeros(n_outputs, n_features)
          @bias_term = Xumo::DFloat.zeros(n_outputs)
          if enable_parallel?
            models = parallel_map(n_outputs) { |n| partial_fit(x, y[true, n]) }
            n_outputs.times { |n| @weight_vec[n, true], @bias_term[n] = models[n] }
          else
            n_outputs.times { |n| @weight_vec[n, true], @bias_term[n] = partial_fit(x, y[true, n]) }
          end
        else
          @weight_vec, @bias_term = partial_fit(x, y)
        end
        self
      end

      # Predict values for samples.
      #
      # @param x [Xumo::DFloat] (shape: [n_samples, n_features]) The samples to predict the values.
      # @return [Xumo::DFloat] (shape: [n_samples, n_outputs]) Predicted values per sample.
      def predict(x)
        x = check_convert_sample_array(x)
        x.dot(@weight_vec.transpose) + @bias_term
      end

      # Dump marshal data.
      # @return [Hash] The marshal data about Lasso.
      def marshal_dump
        { params: @params,
          weight_vec: @weight_vec,
          bias_term: @bias_term,
          rng: @rng }
      end

      # Load marshal data.
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @weight_vec = obj[:weight_vec]
        @bias_term = obj[:bias_term]
        @rng = obj[:rng]
        nil
      end

      private

      def partial_fit(x, y)
        n_features = @params[:fit_bias] ? x.shape[1] + 1 : x.shape[1]
        @left_weight = Xumo::DFloat.zeros(n_features)
        @right_weight = Xumo::DFloat.zeros(n_features)
        @left_optimizer = @params[:optimizer].dup
        @right_optimizer = @params[:optimizer].dup
        super
      end

      def calc_loss_gradient(x, y, weight)
        2.0 * (x.dot(weight) - y)
      end

      def calc_new_weight(_optimizer, x, _weight, loss_gradient)
        @left_weight = round_weight(@left_optimizer.call(@left_weight, calc_weight_gradient(loss_gradient, x)))
        @right_weight = round_weight(@right_optimizer.call(@right_weight, calc_weight_gradient(-loss_gradient, x)))
        @left_weight - @right_weight
      end

      def calc_weight_gradient(loss_gradient, data)
        ((@params[:reg_param] + loss_gradient).expand_dims(1) * data).mean(0)
      end

      def round_weight(weight)
        0.5 * (weight + weight.abs)
      end
    end
  end
end
