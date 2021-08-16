json.extract! reference, :id, :bibtex, :short_ref, :created_at, :updated_at

json.measurements reference.measurements do |measurement|
    json.(measurement, :id)
end

json.fell_phases reference.fell_phases do |fell_phase|
    json.(fell_phase, :id)
end

json.url reference_url(reference, format: :json)
