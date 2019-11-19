# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::EvaluationMeasure::ROCAUC do
  let(:roc_auc) { described_class.new }
  let(:y_bin) { Xumo::Int32[1, 1, 2, 2] }
  let(:y_bin_score) { Xumo::DFloat[0.1, 0.4, 0.35, 0.8] }
  let(:y_mult) do
    Xumo::Int32[[1, 0, 0],
                [0, 1, 0],
                [0, 1, 0],
                [0, 0, 1],
                [1, 0, 0],
                [1, 0, 0],
                [0, 0, 1],
                [0, 0, 1],
                [0, 0, 1],
                [1, 0, 0]]
  end
  let(:y_mult_score) do
    Xumo::DFloat[[0.5, 0.4, 0.1],
                 [0.1, 0.8, 0.1],
                 [0.3, 0.5, 0.2],
                 [0.5, 0.2, 0.3],
                 [0.8, 0.1, 0.1],
                 [0.1, 0.7, 0.2],
                 [0.2, 0.7, 0.1],
                 [0.3, 0.2, 0.5],
                 [0.3, 0.5, 0.2],
                 [0.7, 0.1, 0.2]]
  end

  it 'caclulates ROC-AUC.' do
    expect(roc_auc.score(y_bin, y_bin_score)).to eq(0.75)
    expect(roc_auc.score(y_mult, y_mult_score)).to eq(0.78125)

    labels = %w[A B B C A A C C C A]
    label_encoder = Rumale::Preprocessing::LabelEncoder.new
    y = label_encoder.fit_transform(labels)
    onehot_encoder = Rumale::Preprocessing::OneHotEncoder.new
    y_onehot = onehot_encoder.fit_transform(y)
    expect(roc_auc.score(y_onehot, y_mult_score)).to eq(0.78125)
  end

  it 'calculates receiver operating characteristic curve.' do
    fpr, tpr, thd = roc_auc.roc_curve(y_bin, y_bin_score, 2)
    expect(fpr).to eq(Xumo::DFloat[0, 0, 0.5, 0.5, 1])
    expect(tpr).to eq(Xumo::DFloat[0, 0.5, 0.5, 1, 1])
    expect(thd).to eq(Xumo::DFloat[1.8, 0.8, 0.4, 0.35, 0.1])
  end

  it 'calculates area under the ROC.' do
    fpr, tpr, = roc_auc.roc_curve(y_bin, y_bin_score, 2)
    expect(roc_auc.auc(fpr, tpr)).to eq(0.75)
  end

  it 'raises ArgumentError given different shape arrays to the score method.' do
    expect { roc_auc.score(Xumo::Int32[0, 1, 2], Xumo::DFloat[0.1, 0.2]) }.to raise_error(ArgumentError)
    expect { roc_auc.score(Xumo::Int32[[0, 1, 2], [3, 4, 5]], Xumo::DFloat[0.1, 0.2, 0.8]) }.to raise_error(ArgumentError)
    expect { roc_auc.score(Xumo::Int32[0, 1, 2], Xumo::DFloat[[0.1, 0.2, 0.8], [0.8, 0.1, 0.2]]) }.to raise_error(ArgumentError)
  end

  it 'raises ArgumentError given 2-D arrays to the roc_curve method.' do
    expect { roc_auc.roc_curve(Xumo::Int32[[0, 1, 2], [2, 3, 4]], Xumo::DFloat[1, 2, 3]) }.to raise_error(ArgumentError)
    expect { roc_auc.roc_curve(Xumo::Int32[0, 1, 2], Xumo::DFloat[[1, 2, 3], [4, 5, 6]]) }.to raise_error(ArgumentError)
    expect { roc_auc.roc_curve(Xumo::Int32[[0, 1, 2], [2, 3, 4]], Xumo::DFloat[[1, 2, 3], [4, 5, 6]]) }.to raise_error(ArgumentError)
  end

  it 'raises ArgumentError given non-existent label to the roc_curve method.' do
    expect { roc_auc.roc_curve(Xumo::Int32[0, 1, 2], Xumo::DFloat[0.1, 0.2, 0.8], 3) }.to raise_error(ArgumentError)
  end

  it 'raises ArgumentError given ground truth multi-label to the roc_curve method.' do
    expect { roc_auc.roc_curve(Xumo::Int32[0, 1, 2], Xumo::DFloat[0.1, 0.2, 0.8]) }.to raise_error(ArgumentError)
  end

  it 'raises ArgumentError given 2-D arrays to the auc method.' do
    expect { roc_auc.auc(Xumo::Int32[[0, 1, 2], [2, 3, 4]], Xumo::Int32[1, 2, 3]) }.to raise_error(ArgumentError)
    expect { roc_auc.auc(Xumo::Int32[0, 1, 2], Xumo::Int32[[1, 2, 3], [4, 5, 6]]) }.to raise_error(ArgumentError)
    expect { roc_auc.auc(Xumo::Int32[[0, 1, 2], [2, 3, 4]], Xumo::Int32[[1, 2, 3], [4, 5, 6]]) }.to raise_error(ArgumentError)
  end

  it 'raises ArgumentError given arrays with only one elemetn to the auc method.' do
    expect { roc_auc.auc(Xumo::Int32[0, 1, 2], Xumo::Int32[1]) }.to raise_error(ArgumentError)
    expect { roc_auc.auc(Xumo::Int32[0], Xumo::Int32[1, 2, 3]) }.to raise_error(ArgumentError)
    expect { roc_auc.auc(Xumo::Int32[0], Xumo::Int32[1]) }.to raise_error(ArgumentError)
  end
end
