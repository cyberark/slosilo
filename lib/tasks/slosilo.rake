namespace :slosilo do
  desc "Dump a public key"
  task :dump, [:name] => :environment do |t, args|
    args.with_defaults(:name => :own)
    puts Slosilo[args[:name]]
  end

  desc "Generate a key pair"
  task :generate, [:name] => :environment do |t, args|
    args.with_defaults(:name => :own)
    key = Slosilo::Key.new
    Slosilo[args[:name]] = key
    puts key
  end
end
