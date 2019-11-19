# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::EvaluationMeasure::LogLoss do
  let(:bin_ground_truth) { Xumo::Int32[1, 1, 1, 1, 1, -1, -1, -1, -1, -1] }
  let(:bin_predicted) { Xumo::DFloat[0.9, 0.8, 0.6, 0.6, 0.8, 0.1, 0.2, 0.4, 0.4, 0.2] }
  let(:mult_ground_truth) { Xumo::Int32[1, 0, 0, 2] }
  let(:mult_predicted) { Xumo::DFloat[[0.3, 0.5, 0.2], [0.7, 0.3, 0.0], [0.7, 0.2, 0.1], [0.1, 0.1, 0.8]] }

  it 'calculates logarithmic loss for binary classification task.' do
    evaluator = described_class.new
    log_loss = evaluator.score(bin_ground_truth, bin_predicted)
    expect(log_loss.class).to eq(Float)
    expect(log_loss).to be_within(1e-6).of(0.314659)
  end

  it 'calculates logarithmic loss for multilabel classification task.' do
    evaluator = described_class.new
    log_loss = evaluator.score(mult_ground_truth, mult_predicted)
    expect(log_loss.class).to eq(Float)
    expect(log_loss).to be_within(1e-6).of(0.407410)
  end
end
