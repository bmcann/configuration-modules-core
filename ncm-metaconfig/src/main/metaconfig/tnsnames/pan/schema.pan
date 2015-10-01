declaration template metaconfig/tnsnames/schema;

include 'pan/types';

# Protocol address section
type address_parameter = {
    'protocol' : string = 'TCP' with match(SELF,'^(TCP|UDP)$')
    'host' : type_hostname
    'port' : long(0..) = 1521
} = dict();

type address_list = {
    'load_balance' ? string with match(SELF,'^(ON|OFF|YES|NO|TRUE|FALSE)$')
    'failover' ? string with match(SELF,'^(ON|OFF|YES|NO|TRUE|FALSE)$')
    'address' : address_parameter[]
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
type tnsnames_service = {
    'net_service_name' : string
    'protocol_address' : address_list[]
    'connect_data' : connect_data_parameter[1]
    'security' ? security_parameter[1]
};
