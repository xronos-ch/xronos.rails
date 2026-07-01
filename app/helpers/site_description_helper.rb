# frozen_string_literal: true

##
# Helpers for the Site description partials.
module SiteDescriptionHelper
  ##
  # Returns a CSS Grid layout descriptor for the given image count.
  # The image grid container is expected to use +display: grid+ with
  # +aspect-ratio: 4 / 3+, so the overall height is always 4:3 of the
  # container width. Individual cells are not required to be 4:3.
  #
  # Layouts:
  #
  # * 1 image: single cell filling the grid
  # * 2 images: two equal cells side by side
  # * 3 images: hero on the left (spans 2 rows) + 2 small stacked on the right
  # * 4 images: 2x2 grid
  # * 5 images: hero on the left (spans 2 rows) + 2x2 grid of small on the right
  def site_description_image_grid_layout(count)
    case count
    when 1
      { columns: '1fr', rows: '1fr', cells: [{ grid_column: '1', grid_row: '1' }] }
    when 2
      { columns: '1fr 1fr', rows: '1fr', cells: [
        { grid_column: '1', grid_row: '1' },
        { grid_column: '2', grid_row: '1' }
      ] }
    when 3
      { columns: '2fr 1fr', rows: '1fr 1fr', cells: [
        { grid_column: '1', grid_row: '1 / 3' },
        { grid_column: '2', grid_row: '1' },
        { grid_column: '2', grid_row: '2' }
      ] }
    when 4
      { columns: '1fr 1fr', rows: '1fr 1fr', cells: [
        { grid_column: '1', grid_row: '1' },
        { grid_column: '2', grid_row: '1' },
        { grid_column: '1', grid_row: '2' },
        { grid_column: '2', grid_row: '2' }
      ] }
    when 5
      { columns: '2fr 1fr 1fr', rows: '1fr 1fr', cells: [
        { grid_column: '1', grid_row: '1 / 3' },
        { grid_column: '2', grid_row: '1' },
        { grid_column: '3', grid_row: '1' },
        { grid_column: '2', grid_row: '2' },
        { grid_column: '3', grid_row: '2' }
      ] }
    end
  end
end
