# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::Tree::ExtraTreeRegressor do
  let(:x) { two_clusters_dataset[0] }
  let(:y) { x[true, 0] + x[true, 1]**2 }
  let(:y_mult) { Xumo::DFloat[x[true, 0].to_a, (x[true, 1]**2).to_a].transpose.dot(Xumo::DFloat[[0.6, 0.4], [0.8, 0.2]]) }
  let(:max_depth) { nil }
  let(:max_leaf_nodes) { nil }
  let(:min_samples_leaf) { 1 }
  let(:max_features) { nil }
  let(:estimator) do
    described_class.new(max_depth: max_depth, max_leaf_nodes: max_leaf_nodes,
                        min_samples_leaf: min_samples_leaf, max_features: max_features, random_seed: 1)
  end
  let(:estimator_mae) { described_class.new(criterion: 'mae') }

  it 'learns the model for single regression problem.' do
    n_samples, n_features = x.shape

    estimator.fit(x, y)

    expect(estimator.tree.class).to eq(Rumale::Tree::Node)
    expect(estimator.feature_importances.class).to eq(Xumo::DFloat)
    expect(estimator.feature_importances.shape[0]).to eq(n_features)
    expect(estimator.feature_importances.shape[1]).to be_nil
    expect(estimator.leaf_values.class).to eq(Xumo::DFloat)
    expect(estimator.leaf_values.shape[0]).not_to be_zero
    expect(estimator.leaf_values.shape[1]).to be_nil

    predicted = estimator.predict(x)
    expect(predicted.class).to eq(Xumo::DFloat)
    expect(predicted.shape[0]).to eq(n_samples)
    expect(predicted.shape[1]).to be_nil
    expect(estimator.score(x, y)).to be_within(0.01).of(1.0)
  end

  it 'learns the model for multiple regression problem.' do
    n_samples, n_features = x.shape
    n_outputs = y_mult.shape[1]

    estimator.fit(x, y_mult)

    expect(estimator.tree.class).to eq(Rumale::Tree::Node)
    expect(estimator.feature_importances.class).to eq(Xumo::DFloat)
    expect(estimator.feature_importances.shape[0]).to eq(n_features)
    expect(estimator.feature_importances.shape[1]).to be_nil
    expect(estimator.leaf_values.class).to eq(Xumo::DFloat)
    expect(estimator.leaf_values.shape[0]).not_to be_zero
    expect(estimator.leaf_values.shape[1]).to eq(n_outputs)

    predicted = estimator.predict(x)
    expect(predicted.class).to eq(Xumo::DFloat)
    expect(predicted.shape[0]).to eq(n_samples)
    expect(predicted.shape[1]).to eq(n_outputs)
    expect(estimator.score(x, y_mult)).to be_within(0.01).of(1.0)
  end

  it 'dumps and restores itself using Marshal module.' do
    estimator_mae.fit(x, y)
    copied = Marshal.load(Marshal.dump(estimator_mae))
    expect(estimator_mae.class).to eq(copied.class)
    expect(estimator_mae.tree.class).to eq(copied.tree.class)
    expect(estimator_mae.feature_importances).to eq(copied.feature_importances)
    expect(estimator_mae.rng).to eq(copied.rng)
    expect(estimator_mae.score(x, y)).to eq(copied.score(x, y))
  end

  context 'when max_depth parameter is given' do
    let(:max_depth) { 1 }
    it 'learns model with given parameters.' do
      estimator.fit(x, y)
      expect(estimator.params[:max_depth]).to eq(max_depth)
      expect(estimator.tree.left.left).to be_nil
      expect(estimator.tree.left.right).to be_nil
      expect(estimator.tree.right.left).to be_nil
      expect(estimator.tree.right.right).to be_nil
    end
  end

  context 'when max_leaf_nodes parameter is given' do
    let(:max_leaf_nodes) { 2 }
    it 'learns model with given parameters.' do
      estimator.fit(x, y)
      expect(estimator.params[:max_leaf_nodes]).to eq(max_leaf_nodes)
      expect(estimator.leaf_values.size).to eq(max_leaf_nodes)
    end
  end

  context 'when min_samples_leaf parameter is given' do
    let(:min_samples_leaf) { 150 }
    it 'learns model with given parameters.' do
      estimator.fit(x, y)
      expect(estimator.params[:min_samples_leaf]).to eq(min_samples_leaf)
      expect(estimator.tree.left.leaf).to be_truthy
      expect(estimator.tree.left.n_samples).to be >= min_samples_leaf
      expect(estimator.tree.right).to be_nil
    end
  end

  context 'when max_features parameter is given' do
    context 'negative value' do
      let(:max_features) { -10 }
      it 'raises ArgumentError by validation' do
        expect { estimator }.to raise_error(ArgumentError)
      end
    end

    context 'value larger than number of features' do
      let(:max_features) { 10 }
      it 'value of max_features is equal to the number of features' do
        estimator.fit(x, y)
        expect(estimator.params[:max_features]).to eq(x.shape[1])
      end
    end

    context 'valid value' do
      let(:max_features) { 2 }
      it 'learns model with given parameters.' do
        estimator.fit(x, y)
        expect(estimator.params[:max_features]).to eq(2)
      end
    end
  end
end
