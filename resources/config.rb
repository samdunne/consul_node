property :instance_name, String, name_property: true
property :type, kind_of: String
property :config_hash, kind_of: Hash, required: true
property :service_name, kind_of: String, default: 'consul'

action :create do

  pp new_resource
  config_hash = type.nil? ? new_resource.config_hash : {type => new_resource.config_hash}

  file "#{node['chef-consul']['config_dir']}/#{instance_name}.json" do
    owner node['chef-consul']['user']
    group node['chef-consul']['group']
    content JSON.pretty_generate(config_hash)
    notifies :restart, "service[#{service_name}]", :immediately
  end

  service service_name do
    action :nothing
  end
end

action :delete do

  file "#{config_dir}/#{instance_name}.json" do
    action :delete
  end

end
