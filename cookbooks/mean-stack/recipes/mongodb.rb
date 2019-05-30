secret=Chef::EncryptedDataBagItem.load_secret("/home/vagrant/.my_secret_key")
credentials=Chef::EncryptedDataBagItem.load("credentials","credentials",secret)
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
        :admin_user     => credentials["db_admin_user"],
        :admin_pass     => credentials["db_admin_password"]
    })
end
template '/tmp/create_app_user.js' do
    source 'create_app_user.js.erb'
    action :create
    variables({
        :app_user     =>    credentials["db_app_user"],
        :app_pass     =>    credentials["db_app_password"]
    })
end
template '/tmp/check_app_user.js' do
    source 'check_app_user.js.erb'
    action :create
    variables({
        :app_user     => credentials["db_app_user"]
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
    command "mongo  -u #{credentials["db_app_user"]} -p #{credentials["db_admin_password"]} admin < /tmp/create_app_user.js"
    action :run
    only_if { `mongo --quiet -u #{credentials["db_app_user"]} -p #{credentials["db_admin_password"]} admin < /tmp/check_app_user.js`.include? "0" }
end

[ '/tmp/create_admin.js','/tmp/create_app_user.js','/tmp/check_app_user.js'].each do | f |
    file f do
        action :delete
    end
end