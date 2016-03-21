object template alternative;

include 'metaconfig/tnsnames/config';

#prefix '/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents';
#'connections/net_service_name' = 'NET_SERVICE_NAME';
#'connections/protocol_address' = dict('listener_addresses', list(dict('host', 'ponzi.lab.ac.uk',)));
#'connections/connect_data' = dict('service_name', 'service_name.lab.ac.uk', 'server', 'DEDICATED');

'/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents/connections' ?= list();
#'/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents/connections' = merge(SELF, list(
#dict(
#    'net_service_name', 'NET_SERVICE_NAME',
#
#    'protocol_address', list(
#        dict(
#            'listener_addresses', dict(
#                'host', 'ponzi.lab.ac.uk',
#                ),
#            ),
#        ),
#        ),
#
#    'connect_data', dict(
#        'service_name', 'servicename.example.com',
#        'server', 'DEDICATED',
#    ),
#));

'/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents/connections' = append(SELF, dict(
    'net_service_name', 'NET_SERVICE_NAME',

    'protocol_address', list(
    dict(
        'load_balance','ON',
        'failover', 'ON',
        'listener_addresses', list(
        dict(
            'protocol', 'TCP',
            'host', 'chico.example.com',
            'port', 1500,
            ),

        dict(
            'protocol', 'UDP',
            'host', 'harpo.example.com',
            'port', 1600,
            ),),
        ),

    dict(
        'load_balance','OFF',
        'failover', 'OFF',
        'listener_addresses', list(
        dict(
            'protocol', 'TCP',
            'host', 'groucho.example.com',
            'port', 1700,
            ),

        dict(
            'protocol', 'UDP',
            'host', 'zeppo.example.com',
            'port', 1800,
            ),),
        ),
    ),

    'connect_data', list(
    dict(
        'service_name', 'servicename.example.com',
        'rdb_database', 'rdb_filename',
        'global_name', 'global_database_name',
        'server', 'DEDICATED',
        'failover_mode', list(
        dict(
            'backup', 'backupservicename.example.com',
            'type', 'SESSION',
            'method', 'PRECONNECT',
            ),),
        ),
    ),

    'security', list(
    dict(
        'ssl_server_cert_dn', 'cn=schema,cn=database,dc=example,dc=com',
        ),
    )
),
);

'/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents/connections' = append(SELF, dict(
    'net_service_name', 'NET_SERVICE_NAME_2',

    'protocol_address', list(
    dict(
        'listener_addresses', list(
        dict(
            'host', 'ponzi.lab.ac.uk',
            ),
        ),
    ),
),

    'connect_data', list(
    dict(
        'service_name', 'servicename.example.com',
        'server', 'DEDICATED',
        ),
    ),),
);
