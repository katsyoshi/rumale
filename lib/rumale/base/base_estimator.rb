# frozen_string_literal: true

module Rumale
  # This module consists of basic mix-in classes.
  module Base
    # Base module for all estimators in Rumale.
    module BaseEstimator
      # Return parameters about an estimator.
      # @return [Hash]
      attr_reader :params

      private

      def enable_linalg?
        if defined?(Xumo::Linalg).nil?
          warn('If you want to use features that depend on Xumo::Linalg, you should install and load Xumo::Linalg in advance.')
          return false
        end
        if Xumo::Linalg::VERSION < '0.1.4'
          warn('The loaded Xumo::Linalg does not implement the methods required by Rumale. Please load Xumo::Linalg version 0.1.4 or later.')
          return false
        end
        true
      end

      def enable_parallel?
        return false if @params[:n_jobs].nil?
        if defined?(Parallel).nil?
          warn('If you want to use parallel option, you should install and load Parallel in advance.')
          return false
        end
        true
      end

      def n_processes
        return 1 unless enable_parallel?
        @params[:n_jobs] <= 0 ? Parallel.processor_count : @params[:n_jobs]
      end

      def parallel_map(n_outputs, &block)
        Parallel.map(Array.new(n_outputs) { |v| v }, in_processes: n_processes, &block)
      end
    end
  end
end
