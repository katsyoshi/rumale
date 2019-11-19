# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::NearestNeighbors::KNeighborsClassifier do
  let(:three_clusters) { three_clusters_dataset }
  let(:samples) { three_clusters[0] }
  let(:labels) { three_clusters[1] }
  let(:estimator) { described_class.new(n_neighbors: 5) }

  it 'classifies three clusters data.' do
    n_samples, n_features = samples.shape
    estimator.fit(samples, labels)
    expect(estimator.prototypes.class).to eq(Xumo::DFloat)
    expect(estimator.prototypes.shape[0]).to eq(n_samples)
    expect(estimator.prototypes.shape[1]).to eq(n_features)
    expect(estimator.labels.class).to eq(Xumo::Int32)
    expect(estimator.labels.size).to eq(n_samples)
    expect(estimator.classes.class).to eq(Xumo::Int32)
    expect(estimator.classes.size).to eq(3)
    expect(estimator.score(samples, labels)).to eq(1.0)
  end

  it 'dumps and restores itself using Marshal module.' do
    estimator.fit(samples, labels)
    copied = Marshal.load(Marshal.dump(estimator))
    expect(estimator.class).to eq(copied.class)
    expect(estimator.params[:n_neighbors]).to eq(copied.params[:n_neighbors])
    expect(estimator.prototypes).to eq(copied.prototypes)
    expect(estimator.labels).to eq(copied.labels)
    expect(estimator.classes).to eq(copied.classes)
    expect(copied.score(samples, labels)).to eq(1.0)
  end
end
