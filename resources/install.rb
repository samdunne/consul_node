property :instance_name, String, name_property: true
property :version, kind_of: String, default: '0.6.3'

action :install do

  group node['chef-consul']['group'] do
    system true
  end
  user node['chef-consul']['user'] do
    gid node['chef-consul']['group']
    system true
  end

  [node['chef-consul']['config_dir'], node['chef-consul']['data_dir']].each do |dir|
    directory dir do
      owner node['chef-consul']['user']
      group node['chef-consul']['group']
      mode 00700
    end
  end

  remote_file "#{Chef::Config[:file_cache_path]}/consul.zip" do
    source "https://releases.hashicorp.com/consul/#{version}/consul_#{version}_linux_amd64.zip"
  end

  directory "/usr/local/consul-#{version}"
  execute 'install consul' do
    command "unzip #{Chef::Config[:file_cache_path]}/consul.zip -d /usr/local/consul-#{version}"
    creates "/usr/local/consul-#{version}/consul"
  end

  link '/usr/local/bin/consul' do
    to "/usr/local/consul-#{version}/consul"
  end

  case node['init_package']
  when 'systemd'
    template "/etc/systemd/system/#{instance_name}.service" do
      cookbook 'chef-consul'
      source 'init/systemd.erb'
    end
    service instance_name do
      action [ :enable, :start ]
    end
  end
end

action :remove do

  link '/usr/local/bin/consul' do
    action :delete
    only_if {::File.exists?('/usr/local/bin/consul') and ::File.readlink('/usr/local/bin/consul') == "/usr/local/consul-#{version}/consul"}
  end

  directory "/usr/local/consul-#{version}" do
    recursive true
    action :delete
  end
end
