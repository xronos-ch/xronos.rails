json.set! :data do
  json.array! @periods do |period|
    json.partial! 'periods/period', period: period
    json.url  "
              #{link_to 'Show', period }
              #{link_to 'Edit', edit_period_path(period)}
              #{link_to 'Destroy', period, method: :delete, data: { confirm: 'Are you sure?' }}
              "
  end
end