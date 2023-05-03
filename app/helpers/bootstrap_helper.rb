module BootstrapHelper

  def spinner
    content_tag :div, class: "spinner-border spinner-border-sm text-info", role: "status" do
      content_tag :span, class: "visually-hidden" do
        "Loading..."
      end
    end
  end

end
