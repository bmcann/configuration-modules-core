declaration template metaconfig/tnsnames/schema;

include 'pan/types';

type tnsnames_service = {
    'address_name' : string
    'protocol' : string
    'host_name' : type_hostname
    'port' : long(0..)
    'service_name' : string
    'option' ? string
};
