# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::Ensemble::ExtraTreesRegressor do
  let(:x) { two_clusters_dataset[0] }
  let(:y) { x[true, 0] + x[true, 1]**2 }
  let(:y_mult) { Xumo::DFloat[x[true, 0].to_a, (x[true, 1]**2).to_a].transpose.dot(Xumo::DFloat[[0.6, 0.4], [0.0, 0.1]]) }
  let(:n_estimators) { 10 }
  let(:estimator) { described_class.new(n_estimators: n_estimators, criterion: 'mae', max_features: 2, random_seed: 9) }

  it 'learns the model for single regression problem.' do
    n_samples, n_features = x.shape

    estimator.fit(x, y)

    expect(estimator.params[:n_estimators]).to eq(n_estimators)
    expect(estimator.params[:criterion]).to eq('mae')
    expect(estimator.params[:max_features]).to eq(2)
    expect(estimator.estimators.class).to eq(Array)
    expect(estimator.estimators.size).to eq(n_estimators)
    expect(estimator.estimators[0].class).to eq(Rumale::Tree::ExtraTreeRegressor)
    expect(estimator.feature_importances.class).to eq(Xumo::DFloat)
    expect(estimator.feature_importances.shape[0]).to eq(n_features)
    expect(estimator.feature_importances.shape[1]).to be_nil

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

    expect(estimator.estimators.class).to eq(Array)
    expect(estimator.estimators.size).to eq(n_estimators)
    expect(estimator.estimators[0].class).to eq(Rumale::Tree::ExtraTreeRegressor)
    expect(estimator.feature_importances.class).to eq(Xumo::DFloat)
    expect(estimator.feature_importances.shape[0]).to eq(n_features)
    expect(estimator.feature_importances.shape[1]).to be_nil

    predicted = estimator.predict(x)
    expect(predicted.class).to eq(Xumo::DFloat)
    expect(predicted.shape[0]).to eq(n_samples)
    expect(predicted.shape[1]).to eq(n_outputs)
    expect(estimator.score(x, y_mult)).to be_within(0.01).of(1.0)
  end

  it 'returns leaf index that each sample reached.' do
    n_samples, = x.shape
    estimator.fit(x, y)
    index_mat = estimator.apply(x)
    expect(index_mat.shape[0]).to eq(n_samples)
    expect(index_mat.shape[1]).to eq(n_estimators)
    expect(index_mat[true, 0]).to eq(estimator.estimators[0].apply(x))
  end

  it 'dumps and restores itself using Marshal module.' do
    estimator.fit(x, y)
    copied = Marshal.load(Marshal.dump(estimator))
    expect(estimator.class).to eq(copied.class)
    expect(estimator.estimators.size).to eq(copied.estimators.size)
    expect(estimator.feature_importances).to eq(copied.feature_importances)
    expect(estimator.rng).to eq(copied.rng)
    expect(estimator.score(x, y)).to eq(copied.score(x, y))
  end
end
