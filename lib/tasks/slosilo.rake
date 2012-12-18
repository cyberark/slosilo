namespace :slosilo do
  desc "Dump a public key"
  task :dump, [:name] => :environment do |t, args|
    args.with_defaults(:name => :own)
    puts Slosilo[args[:name]]
  end
end
