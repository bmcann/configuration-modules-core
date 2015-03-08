declaration template metaconfig/tnsnames/schema;

include 'pan/types';

type address = {
    'protocol' : string with match(SELF,'^(TCP|UDP)$')
    'host' : type_hostname
    'port' : long(0..)
} = nlist();

type tnsnames_service = {
    'net_service_name' : string
    'load_balance' ? string with match(SELF,'^(ON|OFF|YES|NO|TRUE|FALSE)$')
    'failover' ? string with match(SELF,'^(ON|OFF|YES|NO|TRUE|FALSE)$')
    'addresses' : address[]
    'service_name' : string
    'server' ? string with match(SELF,'^(DEDICATED|SHARED|POOLED)$')
};
