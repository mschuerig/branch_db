
property 'Active Database' do
  ActiveRecord::Base.configurations[RAILS_ENV]['database']
end
