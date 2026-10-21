class RefreshDataViewsJob < ApplicationJob
  queue_as :default

  def perform
    DataView.refresh
  end
end
