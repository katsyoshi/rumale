# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::Validation do
  it 'detects invalid type array given.' do
    expect { described_class.check_sample_array([[1, 2, 3], [4, 5, 6]]) }.to raise_error(TypeError)
    expect { described_class.check_sample_array(Xumo::Int32[[1, 2, 3], [4, 5, 6]]) }.to raise_error(TypeError)
    expect { described_class.check_label_array([1, 2, 3]) }.to raise_error(TypeError)
    expect { described_class.check_label_array(Xumo::DFloat.new([1, 2, 3])) }.to raise_error(TypeError)
    expect { described_class.check_tvalue_array([1, 2, 3]) }.to raise_error(TypeError)
    expect { described_class.check_tvalue_array(Xumo::Int32[1, 2, 3]) }.to raise_error(TypeError)
  end

  it 'detects and converts invalid type array given.' do
    expect(described_class.check_convert_sample_array([[1, 2, 3], [4, 5, 6]])).to eq(Xumo::DFloat[[1, 2, 3], [4, 5, 6]])
    expect(described_class.check_convert_label_array([1, 2, 3])).to eq(Xumo::Int32[1, 2, 3])
    expect(described_class.check_convert_tvalue_array([1, 2, 3])).to eq(Xumo::DFloat[1, 2, 3])
  end

  it 'detects invalid shape array given.' do
    expect { described_class.check_sample_array(Xumo::DFloat[1, 2, 3]) }.to raise_error(ArgumentError)
    expect { described_class.check_label_array(Xumo::Int32[[1, 2, 3], [4, 5, 6]]) }.to raise_error(ArgumentError)
  end

  it 'detects invalid number of samples.' do
    x = Xumo::DFloat[[1, 2], [3, 4], [5, 6]]
    y = Xumo::Int32[1, 2]
    v = Xumo::DFloat[1, 2]
    expect { described_class.check_sample_label_size(x, y) }.to raise_error(ArgumentError)
    expect { described_class.check_sample_tvalue_size(x, v) }.to raise_error(ArgumentError)
  end

  it 'detects invalid type variables given.' do
    expect { described_class.check_params_type(Integer, foo: nil) }.to raise_error(TypeError)
    expect(described_class.check_params_type(Integer, foo: 10)).to be_nil
    expect { described_class.check_params_type_or_nil(Integer, foo: 1.0) }.to raise_error(TypeError)
    expect(described_class.check_params_type_or_nil(Integer, foo: nil)).to be_nil
    expect { described_class.check_params_numeric_or_nil(foo: '1.0') }.to raise_error(TypeError)
    expect(described_class.check_params_numeric_or_nil(foo: 1.0)).to be_nil
    expect(described_class.check_params_numeric_or_nil(foo: nil)).to be_nil
    expect { described_class.check_params_boolean(foo: nil) }.to raise_error(TypeError)
    expect(described_class.check_params_boolean(foo: true)).to be_nil
    expect(described_class.check_params_boolean(foo: false)).to be_nil
    expect { described_class.check_params_integer(foo: 0.5) }.to raise_error(TypeError)
    expect(described_class.check_params_integer(foo: 10)).to be_nil
    expect { described_class.check_params_float(foo: 10) }.to raise_error(TypeError)
    expect(described_class.check_params_float(foo: 0.5)).to be_nil
  end

  it 'detects negative value given.' do
    expect { described_class.check_params_positive(foo: -1) }.to raise_error(ArgumentError)
    expect { described_class.check_params_positive(foo: -0.5) }.to raise_error(ArgumentError)
    expect(described_class.check_params_type(foo: 0)).to be_nil
    expect(described_class.check_params_type(foo: 0.0)).to be_nil
    expect(described_class.check_params_type(foo: 1)).to be_nil
    expect(described_class.check_params_type(foo: 0.5)).to be_nil
    expect(described_class.check_params_type(foo: nil)).to be_nil
  end
end
