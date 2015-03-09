object template config;

include 'metaconfig/tnsnames/config';

prefix '/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents';
'net_service_name' = 'VCERT2_CS';
'address_lists' =
    list(
        nlist(
            'load_balance','ON',
            'failover', 'ON',
            'addresses',  
                list(
                    nlist(
                        'protocol', 'TCP',
                        'host', 'chico.gridpp.rl.ac.uk',
                        'port', 1500,
                         ),
                    nlist(
                        'protocol', 'UDP',
                        'host', 'harpo.gridpp.rl.ac.uk',
                        'port', 1600,
                         ),
                    ),
             ),
        nlist(
            'load_balance','OFF',
            'failover', 'OFF',
            'addresses',
                list(
                    nlist(
                        'protocol', 'TCP',
                        'host', 'groucho.gridpp.rl.ac.uk',
                        'port', 1700,
                         ),
                    nlist(
                        'protocol', 'UDP',
                        'host', 'zeppo.gridpp.rl.ac.uk',
                        'port', 1800,
                         ),
                    ),
             ),
);
'connect_data' = 
    list(
        nlist(
            'service_name', 'vcert2_cs.gridpp.rl.ac.uk',
            'server', 'DEDICATED',
            'failover_settings',
                list(
                    nlist(
                        'backup', 'ponzi.gridpp.rl.ac.uk',
                        'type', 'SESSION',
                        'method', 'PRECONNECT',
                         ),
                    ),
             ),
);
