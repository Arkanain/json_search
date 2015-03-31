namespace :ng do
  namespace :db do
    task :migrate => :environment do
      # run migration
    end
  end

  namespace :generate do
    #TODO: how send param to rake task
    task :model => :environment do |t_name|
      # generate model
    end
  end
end