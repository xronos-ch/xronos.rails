# frozen_string_literal: true

# Pagy initializer file
# See https://ddnexus.github.io/pagy/toolbox/configuration/initializer/

Pagy::OPTIONS[:ttl]           = 300    # Time to live for memoised count with countish paginator
Pagy::OPTIONS[:anchor_string] = 'data-turbo-action="advance"' # Pagination adds to the history stack

# Freeze options for safety and performance
Pagy::OPTIONS.freeze 

