object template alternative;

include 'metaconfig/tnsnames/config';

prefix '/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents';
'net_service_name' = 'SERVICE_NAME';
'address_lists' = list(nlist('addresses', list(nlist('protocol', 'TCP', 'host', 'ponzi.lab.ac.uk', 'port', 1521,))));
'connect_data' = list(nlist('service_name', 'service_name.lab.ac.uk', 'server', 'DEDICATED'));
