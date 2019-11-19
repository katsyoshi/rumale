# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::KernelMachine::KernelRidge do
  let(:x) { two_clusters_dataset[0] }
  let(:n_samples) { x.shape[0] }
  let(:kernel_mat) { Rumale::PairwiseMetric.rbf_kernel(x, nil, 1.0) }
  let(:reg_param) { 1.0 }
  let(:estimator) { described_class.new(reg_param: reg_param).fit(kernel_mat, y) }
  let(:predicted) { estimator.predict(kernel_mat) }
  let(:score) { estimator.score(kernel_mat, y) }
  let(:copied) { Marshal.load(Marshal.dump(estimator)) }

  context 'when single regression problem' do
    let(:y) { x[true, 0] + x[true, 1]**2 }

    it 'learns the model.', :aggregate_failures do
      expect(estimator.weight_vec.class).to eq(Xumo::DFloat)
      expect(estimator.weight_vec.ndim).to eq(1)
      expect(estimator.weight_vec.shape[0]).to eq(n_samples)
      expect(predicted.class).to eq(Xumo::DFloat)
      expect(predicted.ndim).to eq(1)
      expect(predicted.shape[0]).to eq(n_samples)
      expect(score).to be_within(0.01).of(1.0)
    end

    it 'dumps and restores itself using Marshal module.', :aggregate_failures do
      expect(estimator.class).to eq(copied.class)
      expect(estimator.params[:reg_param]).to eq(estimator.params[:reg_param])
      expect(estimator.weight_vec).to eq(copied.weight_vec)
      expect(score).to eq(copied.score(kernel_mat, y))
    end
  end

  context 'when multiple regression problem' do
    let(:y) { Xumo::DFloat[x[true, 0].to_a, (x[true, 1]**2).to_a].transpose.dot(Xumo::DFloat[[0.6, 0.4], [0.8, 0.2]]) }
    let(:n_outputs) { y.shape[1] }

    it 'learns the model.', :aggregate_failures do
      expect(estimator.weight_vec.class).to eq(Xumo::DFloat)
      expect(estimator.weight_vec.ndim).to eq(2)
      expect(estimator.weight_vec.shape[0]).to eq(n_samples)
      expect(estimator.weight_vec.shape[1]).to eq(n_outputs)
      expect(predicted.class).to eq(Xumo::DFloat)
      expect(predicted.ndim).to eq(2)
      expect(predicted.shape[0]).to eq(n_samples)
      expect(predicted.shape[1]).to eq(n_outputs)
      expect(score).to be_within(0.01).of(1.0)
    end

    context 'when given array to reg_param' do
      let(:reg_param) { Xumo::DFloat[0.1, 0.5] }

      it 'learns the model.', :aggregate_failures do
        expect(estimator.weight_vec.class).to eq(Xumo::DFloat)
        expect(estimator.weight_vec.ndim).to eq(2)
        expect(estimator.weight_vec.shape[0]).to eq(n_samples)
        expect(estimator.weight_vec.shape[1]).to eq(n_outputs)
        expect(estimator.params[:reg_param]).to eq(reg_param)
        expect(predicted.class).to eq(Xumo::DFloat)
        expect(predicted.ndim).to eq(2)
        expect(predicted.shape[0]).to eq(n_samples)
        expect(predicted.shape[1]).to eq(n_outputs)
        expect(score).to be_within(0.01).of(1.0)
      end
    end
  end

  describe 'validation' do
    it 'raises TypeError when given invalid type value to reg_param.', :aggregate_failures do
      expect { described_class.new(reg_param: '1.0') }.to raise_error(TypeError)
      expect { described_class.new(reg_param: [1.0, 1.0]) }.to raise_error(TypeError)
    end

    it 'raises ArgumentError when given non 1-D array to reg_param.' do
      expect { described_class.new(reg_param: Xumo::DFloat[[0.1, 0.2], [0.3, 0.4]]) }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError when given reg_param an array with a diffrent size from the target variable array.' do
      estimator = described_class.new(reg_param: Xumo::DFloat[0.1, 0.2, 0.3])
      expect { estimator.fit(kernel_mat, Xumo::DFloat.new(n_samples, 2).rand) }.to raise_error(ArgumentError)
    end
  end
end
