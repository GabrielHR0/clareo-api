require_relative "../../domain_helper"

RSpec.describe Post do
  def post(**overrides)
    described_class.build(
      institution_id: "ins_1",
      title: "Atualização",
      content: "Conteúdo do feed",
      **overrides
    )
  end

  it "is published immediately" do
    expect(post).to be_published
    expect(post).not_to be_hidden
  end

  it "can belong to a campaign" do
    expect(post(campaign_id: 7)).to be_campaign
    expect(post).not_to be_campaign
  end

  it "still requires title and content" do
    expect { post(title: " ") }.to raise_error(InvalidPost, /title/)
    expect { post(content: " ") }.to raise_error(InvalidPost, /content/)
  end

  it "hides instead of deleting, preserving references" do
    hidden = post.hide!

    expect(hidden).to be_hidden
    expect(hidden.publish!).to be_published
  end
end
