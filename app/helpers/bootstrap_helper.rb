module BootstrapHelper

  def accordion_item(id, title, collapsed = true)
    content_tag :div, class: "accordion-item bg-transparent border-0" do
      header = accordion_header id, title, collapsed
      collapse = accordion_collapse id, collapsed do
        yield
      end
      header + collapse
    end
  end


  def spinner
    content_tag :div, class: "spinner-border spinner-border-sm text-info", role: "status" do
      content_tag :span, class: "visually-hidden" do
        "Loading..."
      end
    end
  end

  protected

  def accordion_header(id, title, collapsed)
    content_tag :h2, class: "accordion-header" do
      accordion_button id, title, collapsed
    end
  end

  def accordion_button(id, title, collapsed)
    classes = [ "accordion-button", "bg-transparent" ]
    classes.push("collapsed") if collapsed
    button_tag title, name: nil, class: classes.join(" "), type: :button,
      data: { bs_toggle: "collapse", bs_target: "#" + id.to_s },
      aria: { expanded: !collapsed, controls: id }
  end

  def accordion_collapse(id, collapsed)
    classes = [ "accordion-collapse", "collapse" ]
    classes.push("show") unless collapsed
    content_tag :div, id: id, class: classes.join(" ") do
      accordion_body do
        yield
      end
    end
  end

  def accordion_body
    content_tag :div, class: "accordion-body" do
      yield
    end
  end

end
