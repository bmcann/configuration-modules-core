object template config;

include 'metaconfig/tnsnames/config';

prefix '/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents';
'net_service_name' = 'VCERT2_CS';
'load_balance' = 'ON';
'failover' = 'ON';
'addresses' = 
    list(
        nlist(
            'protocol', 'TCP',
            'host', 'lcgdb51.gridpp.rl.ac.uk',
            'port', 1521,
             ),
        );
'service_name' = 'vcert2_cs.gridpp.rl.ac.uk';
'server' = 'DEDICATED';
