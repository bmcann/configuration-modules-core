object template alternative;

include 'metaconfig/tnsnames/config';

prefix '/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents';
'net_service_name' = 'NET_SERVICE_NAME';
'protocol_address' = list(dict('addresses', list(dict('host', 'ponzi.lab.ac.uk',))));
'connect_data' = list(dict('service_name', 'service_name.lab.ac.uk', 'server', 'DEDICATED'));
