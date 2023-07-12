namespace :rickmorty do
  desc "Manage the Rick & Morty API service cache"
  task cleanup: :environment do
    Rails.cache.cleanup
  end

  task clear_cache: :environment do
    Rails.cache.clear
  end
end
