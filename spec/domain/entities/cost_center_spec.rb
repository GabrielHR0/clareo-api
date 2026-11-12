require_relative "../../domain_helper"

RSpec.describe CostCenter do
  def cost_center(**overrides)
    described_class.build(institution_id: "ins_1", code: "campanha-dekishibolas", name: "Dekishibolas", **overrides)
  end

  it "carries code and name" do
    expect(cost_center.code).to eq("campanha-dekishibolas")
    expect(cost_center.name).to eq("Dekishibolas")
  end

  it "normalizes the code, because the institution types it" do
    expect(described_class.build(institution_id: "ins_1", code: "  c1  ", name: "X").code).to eq("c1")
  end

  it "is identified by institution plus code" do
    expect(cost_center).to eq(described_class.build(institution_id: "ins_1", code: "campanha-dekishibolas", name: "Outro"))
  end

  it "requires an institution, because a cost centre from another tenant is a bug" do
    expect { described_class.build(institution_id: nil, code: "c1", name: "X") }
      .to raise_error(InvalidCostCenter, /institution is required/)
  end

  it "requires a code" do
    expect { cost_center(code: "") }.to raise_error(InvalidCostCenter, /code cannot be blank/)
  end

  it "requires a name" do
    expect { cost_center(name: nil) }.to raise_error(InvalidCostCenter, /name cannot be blank/)
  end
end
