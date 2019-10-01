# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::EvaluationMeasure::MeanSquaredError do
  let(:ground_truth) { Xumo::DFloat[3.2, -0.2, 2.2, 6.8] }
  let(:estimated) { Xumo::DFloat[2.9, -0.1, 2.3, 7.2] }
  let(:mult_ground_truth) { Xumo::DFloat[[0.5, 1.9], [-0.7, 1.8], [7.9, -6.5]] }
  let(:mult_estimated) { Xumo::DFloat[[0.4, 2.0], [-0.8, 2.2], [8.3, -5.8]] }
  let(:evaluator) { described_class.new }

  it 'calculates mean squared error for single regression task.' do
    mse = evaluator.score(ground_truth, estimated)
    expect(mse.class).to eq(Float)
    expect(mse).to be_within(1e-4).of(0.0675)
  end

  it 'calculates mean squared error for multiple regression task.' do
    mse = evaluator.score(mult_ground_truth, mult_estimated)
    expect(mse.class).to eq(Float)
    expect(mse).to be_within(1e-4).of(0.140)
  end

  it 'raises ArgumentError when the arrays with different shapes are given.' do
    expect { evaluator.score(ground_truth, mult_estimated) }.to raise_error(ArgumentError)
  end
end
