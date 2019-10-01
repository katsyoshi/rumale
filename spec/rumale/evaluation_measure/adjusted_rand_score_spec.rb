# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::EvaluationMeasure::AdjustedRandScore do
  let(:ground_truth) { Xumo::Int32[0, 0, 0, 1, 1, 1] }
  let(:predicted_a) { Xumo::Int32[0, 0, 1, 1, 2, 2] }
  let(:predicted_b) { Xumo::Int32[1, 1, 0, 0, 2, 2] }

  it 'calculates adjuested rand score of clustering result.' do
    evaluator = described_class.new
    ari = evaluator.score(ground_truth, predicted_a)
    expect(ari.class).to eq(Float)
    expect(ari).to be_within(5e-4).of(0.2424)
    ari = evaluator.score(ground_truth, predicted_b)
    expect(ari).to be_within(5e-4).of(0.2424)
  end

  it 'returns one on special cases.' do
    evaluator = described_class.new
    expect(evaluator.score(Xumo::Int32[0, 1, 2], Xumo::Int32[3, 4, 5])).to eq(1.0)
    expect(evaluator.score(Xumo::Int32[0, 0, 0], Xumo::Int32[1, 1, 1])).to eq(1.0)
    expect(evaluator.score(Xumo::Int32[], Xumo::Int32[])).to eq(1.0)
  end
end
