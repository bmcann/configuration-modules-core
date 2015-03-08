declaration template metaconfig/tnsnames/schema;

include 'pan/types';

type tnsnames_service = {
    'net_service_name' : string
    'load_balance' ? boolean
    'failover' ? boolean
    'protocol' : string
    'host_name' : type_hostname
    'port' : long(0..)
    'service_name' : string
    'option' ? string
};
