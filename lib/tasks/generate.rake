namespace :slosilo do
  desc "Generate a new keypair and store it in the keystore."
  task :generate, [:name] => :environment do |t, args|
    kp = Slosilo.create_keypair :name
    puts kp.public_key.export
  end
end
