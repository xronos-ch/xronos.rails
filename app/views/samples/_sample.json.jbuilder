json.extract! sample, :id, :created_at, :updated_at

json.arch_object do
#  json.partial! "/arch_objects/arch_object", arch_object: sample.arch_object
end

#json.measurements sample.measurements do |measurement|
#    json.(measurement, :id)
#end


json.url sample_url(sample, format: :json)
