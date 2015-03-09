object template config;

include 'metaconfig/tnsnames/config';

prefix '/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents';
'net_service_name' = 'NET_SERVICE_NAME';
'address_lists' =
    list(
        nlist(
            'load_balance','ON',
            'failover', 'ON',
            'addresses',  
                list(
                    nlist(
                        'protocol', 'TCP',
                        'host', 'chico.lab.ac.uk',
                        'port', 1500,
                         ),
                    nlist(
                        'protocol', 'UDP',
                        'host', 'harpo.lab.ac.uk',
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
                        'host', 'groucho.lab.ac.uk',
                        'port', 1700,
                         ),
                    nlist(
                        'protocol', 'UDP',
                        'host', 'zeppo.lab.ac.uk',
                        'port', 1800,
                         ),
                    ),
             ),
);
'connect_data' = 
    list(
        nlist(
            'service_name', 'service_name.lab.ac.uk',
            'server', 'DEDICATED',
            'failover_settings',
                list(
                    nlist(
                        'backup', 'ponzi.lab.ac.uk',
                        'type', 'SESSION',
                        'method', 'PRECONNECT',
                         ),
                    ),
             ),
);
