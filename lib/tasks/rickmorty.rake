namespace :rickmorty do
  desc "Manage the Rick & Morty API service cache"
  task clear_cache: :environment do
    Rails.cache.cleanup
  end

end
