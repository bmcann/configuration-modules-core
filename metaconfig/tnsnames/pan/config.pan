unique template metaconfig/tnsnames/config;

include 'metaconfig/tnsnames/schema';

bind "/software/components/metaconfig/services/{/etc/tnsnames.ora}/contents" = tnsnames_service;

prefix "/software/components/metaconfig/services/{/etc/tnsnames.ora}";
"daemon" = "nsd";
"module" = "tnsnames/main";
