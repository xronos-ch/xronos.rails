# test/support/api_assertions.rb

require "json-schema"

module ApiAssertions
  def json_response
    JSON.parse(response.body)
  end

  def assert_matches_response_schema(schema_name, payload)
    schema_path = Rails.root.join("test/support/schemas/#{schema_name}.json")

    assert(
      JSON::Validator.validate!(schema_path.to_s, payload, strict: true)
    )
  end
end