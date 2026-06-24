require "test_helper"

class FontSmokeTest < ActiveSupport::TestCase
  CUSTOM_FONTS = %w[
    inter-latin-variable-wghtOnly-normal.woff2
    raleway-latin-variable-wghtOnly-normal.woff2
    fira-mono-latin-400-normal.woff2
  ].freeze

  test "all custom font files are resolvable in the asset pipeline" do
    CUSTOM_FONTS.each do |font|
      assert Rails.application.assets.load_path.find(font),
        "Expected #{font} to be resolvable via Propshaft"
    end
  end

  test "frontend.css declares @font-face for all three custom font families" do
    css = Rails.root.join("app/assets/builds/frontend.css").read

    assert_match(/font-family:"Inter"/, css)
    assert_match(/font-family:"Raleway"/, css)
    assert_match(/font-family:"Fira Mono"/, css)
  end
end
