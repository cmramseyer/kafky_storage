require "karafka"
require_dependency Rails.root.join("app/consumers/application_consumer").to_s
require_dependency Rails.root.join("app/consumers/catalog_events_consumer").to_s
require_dependency Rails.root.join("app/consumers/orders_events_consumer").to_s

class KarafkaApp < Karafka::App
  setup do |config|
    config.client_id = "kafky_storage"
    config.kafka = {
      "bootstrap.servers": ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
    }
    config.consumer_persistence = !Rails.env.development?
  end

  routes.draw do
    consumer_group :kafky_storage do
      topic "catalog.events" do
        consumer CatalogEventsConsumer
      end

      topic "orders.events" do
        consumer OrdersEventsConsumer
      end
    end
  end
end
