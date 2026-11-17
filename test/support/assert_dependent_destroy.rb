def assert_dependent_destroy(parent, association, count:)
  # Determine association
  reflection = parent.class.reflect_on_association(association)
  raise ArgumentError, "Unknown association #{association}" unless reflection

  # Ensure children exist via the association
  assert_equal count, parent.public_send(association).count,
    "Expected #{count} #{association} before destroy"

  # Destroy parent (immediately if executed asynchronously)
  perform_enqueued_jobs do
    parent.destroy
  end

  # Reload to avoid cached associations
  parent.reload if parent.persisted?

  # Assert that children were destroyed
  assert_equal 0, parent.public_send(association).count,
    "Expected #{association} to be destroyed with parent"

end

