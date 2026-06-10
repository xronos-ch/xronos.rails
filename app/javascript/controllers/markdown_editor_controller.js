import { Controller } from "@hotwired/stimulus"

import EasyMDE from "easymde" // https://github.com/Ionaru/easy-markdown-editor
import "easymde/dist/easymde.min.css"

// Connects to data-controller="markdown-editor"
export default class extends Controller {
  static targets = ["field"]

  connect() {
    this.editor = new EasyMDE({
      element: this.fieldTarget,
      autoDownloadFontAwesome: false,
      toolbar: [
        { action: EasyMDE.toggleBold, className: "bi-type-bold", title: "Bold" },
        { action: EasyMDE.toggleItalic, className: "bi-type-italic", title: "Italic" },
        { action: EasyMDE.toggleStrikethrough, className: "bi-type-strikethrough", title: "Strikethrough" },
        "|",
        { action: EasyMDE.toggleHeadingSmaller, className: "bi-hash", title: "Heading" },
        { action: EasyMDE.toggleHeadingSmaller, className: "bi-caret-down-fill", title: "Heading Smaller" },
        { action: EasyMDE.toggleHeadingBigger, className: "bi-caret-up-fill", title: "Heading Bigger" },
        { action: () => EasyMDE.toggleHeading(1), className: "bi-type-h1", title: "Heading 1" },
        { action: () => EasyMDE.toggleHeading(2), className: "bi-type-h2", title: "Heading 2" },
        { action: () => EasyMDE.toggleHeading(3), className: "bi-type-h3", title: "Heading 3" },
        "|",
        { action: EasyMDE.toggleCodeBlock, className: "bi-code-slash", title: "Code" },
        { action: EasyMDE.toggleBlockquote, className: "bi-chat-quote", title: "Quote" },
        { action: EasyMDE.toggleOrderedList, className: "bi-list-ol", title: "Ordered List" },
        { action: EasyMDE.toggleUnorderedList, className: "bi-list-ul", title: "Unordered List" },
        "|",
        { action: EasyMDE.cleanBlock, className: "bi-x-circle", title: "Clean Block" },
        { action: EasyMDE.drawLink, className: "bi-link-45deg", title: "Insert Link" },
        { action: EasyMDE.drawImage, className: "bi-file-image", title: "Insert Image" },
        { action: EasyMDE.drawImage, className: "bi-cloud-upload", title: "Upload Image" },
        { action: EasyMDE.drawTable, className: "bi-table", title: "Insert Table" },
        { action: EasyMDE.drawHorizontalRule, className: "bi-dash-lg", title: "Insert Horizontal Rule" },
        "|",
        { action: EasyMDE.togglePreview, className: "bi-eye-fill", title: "Preview" },
        { action: EasyMDE.toggleSideBySide, className: "bi-layout-text-sidebar-reverse", title: "Side by Side" },
        { action: EasyMDE.toggleFullScreen, className: "bi-arrows-fullscreen", title: "Fullscreen" },
        "|",
        { action: () => window.open("https://www.markdownguide.org/"), className: "bi-info-circle", title: "Markdown Guide" },
        { action: EasyMDE.undo, className: "bi-arrow-counterclockwise", title: "Undo" },
        { action: EasyMDE.redo, className: "bi-arrow-clockwise", title: "Redo" }
      ],
      spellChecker: false
    })
  }

  disconnect() {
    this.editor.toTextArea()
  }
}