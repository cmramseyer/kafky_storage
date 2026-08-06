require "karafka"

class KarafkaApp < Karafka::App
  setup do |config|
    config.client_id = "kafky_storage"
    config.kafka = {
      "bootstrap.servers": ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
    }
    config.consumer_persistence = !Rails.env.development?
  end
end
