# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::EvaluationMeasure::MutualInformation do
  let(:ground_truth) { Xumo::Int32[0, 0, 0, 1, 1, 1] }
  let(:predicted) { Xumo::Int32[1, 1, 0, 0, 3, 3] }

  it 'calculates mutual information of clustering result.' do
    evaluator = described_class.new
    mi = evaluator.score(ground_truth, predicted)
    expect(mi.class).to eq(Float)
    expect(mi).to be_within(5e-4).of(0.462)
    expect(evaluator.score(Xumo::Int32[1, 1, 0, 0], Xumo::Int32[0, 0, 1, 1])).to be_within(5e-4).of(0.6931)
    expect(evaluator.score(Xumo::Int32[0, 0, 0, 0], Xumo::Int32[0, 1, 2, 3])).to be_zero
  end
end
