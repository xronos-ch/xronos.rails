require "test_helper"

class SourceTest < ActiveSupport::TestCase
  test "factory builds a valid source" do
    source = build(:source)
    assert source.valid?
  end

  test "requires name" do
    source = build(:source, name: nil)
    assert_not source.valid?
    assert_includes source.errors[:name], "can't be blank"
  end

  test "name must be unique per version" do
    create(:source, name: "my_project", version: "v1")
    duplicate = build(:source, name: "my_project", version: "v1")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "same name allowed for different versions" do
    create(:source, name: "my_project", version: "v1")
    other = build(:source, name: "my_project", version: "v2")
    assert other.valid?
  end

  test "same name allowed without version (API sources)" do
    create(:source, name: "my_project", version: "v1")
    api = build(:source, :api, name: "my_project")
    assert api.valid?
  end

  test "label includes version when present" do
    source = build(:source, name: "my_project", version: "v1")
    assert_equal "my_project (v1)", source.label
  end

  test "label omits version when absent" do
    source = build(:source, :api, name: "my_api")
    assert_equal "my_api", source.label
  end

  test "cannot destroy source with imports" do
    source = create(:source)
    create(:import, source: source)
    assert_not source.destroy
    assert_includes source.errors[:base], "Cannot delete record because dependent imports exist"
  end
end
