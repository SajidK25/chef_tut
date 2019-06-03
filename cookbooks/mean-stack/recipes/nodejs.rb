secret=Chef::EncryptedDataBagItem.load_secret("/home/vagrant/.my_secret_key")
credentials=Chef::EncryptedDataBagItem.load("credentials","credentials",secret)

package 'epel-release' do
    action :install
end
package 'nodejs' do
    action :install
end

directory node['app']['dir'] do
    action :create
end

template '/etc/systemd/system/node.service' do
    source 'node.service.erb'
    variables ({
        :appdir     => node['app']['dir']
    })
    # action :create
end

template "#{node['app']['dir']}/server.js" do
    source 'server.js.erb'
    mode '0755'
    variables ({
        :app_port   => node['app']['port'],
        :appdbuser  => credentials["db_app_user"],
        :appdbpass  => credentials["db_app_password"],
        :db_host    => node['db']['host']
    })
    notifies :restart, "service[node]"
end
cookbook_file "#{node['app']['dir']}/package.json" do
    source 'package.json'
    action :create
end
remote_directory "#{node['app']['dir']}/api" do
    source 'api'
    action :create
end

execute 'Run npm against package.json file' do
    command 'npm install'
    cwd node['app']['dir']
    only_if { ::File::exist?("#{node['app']['dir']}/package.json") }
end
service 'node' do
    action [:start,:enable]
end




