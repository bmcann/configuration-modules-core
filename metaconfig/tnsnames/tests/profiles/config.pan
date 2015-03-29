object template config;

include 'metaconfig/tnsnames/config';

prefix '/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents';
'net_service_name' = 'NET_SERVICE_NAME';
'protocol_address' =
    list(
        nlist(
            'load_balance','ON',
            'failover', 'ON',
            'addresses',  
                list(
                    nlist(
                        'protocol', 'TCP',
                        'host', 'chico.example.com',
                        'port', 1500,
                         ),
                    nlist(
                        'protocol', 'UDP',
                        'host', 'harpo.example.com',
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
                        'host', 'groucho.example.com',
                        'port', 1700,
                         ),
                    nlist(
                        'protocol', 'UDP',
                        'host', 'zeppo.example.com',
                        'port', 1800,
                         ),
                    ),
             ),
);
'connect_data' = 
    list(
        nlist(
            'service_name', 'servicename.example.com',
            'server', 'DEDICATED',
            'failover_mode',
                list(
                    nlist(
                        'backup', 'backupservicename.example.com',
                        'type', 'SESSION',
                        'method', 'PRECONNECT',
                         ),
                    ),
             ),
);
