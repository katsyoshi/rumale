# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::LinearModel::BaseLinearModel do
  let(:x) { two_clusters_dataset[0] }
  let(:y) { x.dot(Xumo::DFloat[1.0, 2.0]) }
  let(:estimator) { described_class.new(random_seed: 1) }

  it 'raises NotImplementedError when calls partial_fit method.' do
    expect { estimator.send(:partial_fit, x, y) }.to raise_error(NotImplementedError)
  end

  it 'initializes some parameters.' do
    expect(estimator.params[:reg_param]).to eq(1.0)
    expect(estimator.params[:fit_bias]).to be_falsy
    expect(estimator.params[:bias_scale]).to eq(1.0)
    expect(estimator.params[:max_iter]).to eq(1000)
    expect(estimator.params[:batch_size]).to eq(10)
    expect(estimator.params[:optimizer].class).to eq(Rumale::Optimizer::Nadam)
    expect(estimator.params[:n_jobs]).to be_nil
    expect(estimator.params[:random_seed]).to eq(1)
  end
end
