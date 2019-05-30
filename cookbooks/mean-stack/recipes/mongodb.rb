package "mongodb" do
    action :install
end
# A resource
service "mongodb" do
    action [:start,:enable]
end

template '/tmp/create_admin.js' do
    source 'create_admin.js.erb'
    action :create
    variables({
        :admin_user     => node['db']['admin']['user'],
        :admin_pass     => node['db']['admin']['password']
    })
end
template '/tmp/create_app_user.js' do
    source 'create_app_user.js.erb'
    action :create
    variables({
        :app_user     => node['db']['app']['user'],
        :app_pass     => node['db']['app']['password']
    })
end
template '/tmp/check_app_user.js' do
    source 'check_app_user.js.erb'
    action :create
    variables({
        :app_user     => node['db']['app']['user'],
    })
end

execute 'Create the admin user for the database' do
    command 'mongo < /tmp/create_admin.js'
    action :run
    only_if 'grep "#auth = true" /etc/mongodb.conf'
end
cookbook_file '/etc/mongodb.conf' do
    source 'mongodb.conf'
    action :create
    notifies:restart,"service[mongodb]"
end
execute 'Create the app user for the database' do
    command "mongo  -u #{node['db']['admin']['user']} -p #{node['db']['admin']['password']} admin < /tmp/create_app_user.js"
    action :run
    only_if { `mongo --quiet -u #{node['db']['admin']['user']} -p #{node['db']['admin']['password']} admin < /tmp/check_app_user.js`.include? "0" }
end