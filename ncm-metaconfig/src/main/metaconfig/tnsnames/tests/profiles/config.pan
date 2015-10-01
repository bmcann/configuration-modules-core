object template config;

include 'metaconfig/tnsnames/config';

prefix '/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents';
'net_service_name' = 'NET_SERVICE_NAME';
'protocol_address' =
    list(
        dict(
            'load_balance','ON',
            'failover', 'ON',
            'address',  
                list(
                    dict(
                        'protocol', 'TCP',
                        'host', 'chico.example.com',
                        'port', 1500,
                        ),
                    dict(
                        'protocol', 'UDP',
                        'host', 'harpo.example.com',
                        'port', 1600,
                        ),
                    ),
            ),
        dict(
            'load_balance','OFF',
            'failover', 'OFF',
            'address',
                list(
                    dict(
                        'protocol', 'TCP',
                        'host', 'groucho.example.com',
                        'port', 1700,
                        ),
                    dict(
                        'protocol', 'UDP',
                        'host', 'zeppo.example.com',
                        'port', 1800,
                        ),
                    ),
            ),
);
'connect_data' = 
    list(
        dict(
            'service_name', 'servicename.example.com',
            'rdb_database', 'rdb_filename',
            'global_name', 'global_database_name',
            'server', 'DEDICATED',
            'failover_mode',
                list(
                    dict(
                        'backup', 'backupservicename.example.com',
                        'type', 'SESSION',
                        'method', 'PRECONNECT',
                        ),
                    ),
            ),
);
'security' =
    list(
        dict(
            'ssl_server_cert_dn', 'cn=schema,cn=database,dc=example,dc=com',
            ),
);
