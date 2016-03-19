declaration template metaconfig/tnsnames/schema;

include 'pan/types';

# Protocol address section
type listener_address = {
    'protocol' : string = 'TCP' with match(SELF,'^(TCP|UDP)$')
    'host' : type_hostname
    'port' : long(0..) = 1521
} = dict();

type listener_address_list = {
    'load_balance' ? string with match(SELF,'^(ON|OFF|YES|NO|TRUE|FALSE)$')
    'failover' ? string with match(SELF,'^(ON|OFF|YES|NO|TRUE|FALSE)$')
    'listener_addresses' : listener_address[]
} = dict();

# Connect data section
type failover_parameter = {
    'backup' : string
    'type' : string with match(SELF,'^(SESSION|SELECT|NONE)$')
    'method' : string with match(SELF,'^(BASIC|PRECONNECT)$')
} = dict();

type connect_data_parameter = {
    'service_name' : string
    'rdb_database' ? string # identifies the Oracle Rdb database by its filename
    'global_name' ? string # should only be defined if 'rdb_database' is defined
    'server' ? string with match(SELF,'^(DEDICATED|SHARED|POOLED)$')
    'failover_mode' ? failover_parameter[1]
} = dict();

# Security section
type security_parameter = {
    'ssl_server_cert_dn' : string
} = dict();

# Tnsnames.ora section
type connection_configuration = {
    'net_service_name' : string
    'protocol_address' : listener_address_list[]
    'connect_data' : connect_data_parameter[1]
    'security' ? security_parameter[1]
} = dict();

type tnsnames_service = {
    'connections' ? connection_configuration[]
};



#} = dict() with {
#    if(exists(SELF['load_balance']) && length(SELF[listener_addresses[host]] < 1)) {
#        error("My error");
#    };
#    true;
#};
