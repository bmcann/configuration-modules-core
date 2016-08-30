object template config;

include 'metaconfig/hdfs/config';


bind "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/core-site.xml}/contents" = hdfs_core_site;
bind "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/hdfs-site.xml}/contents/dfs" = hdfs_hdfs_site;
#bind "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/slaves}/contents" = type_hdfs_slaves;

prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/hdfs-site.xml}";
"module" = "hdfs/main";
prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/core-site.xml}";
"module" = "hdfs/main";
#prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/slaves}";

bind "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/gpfs-site.xml}/contents/gpfs" = hdfs_gpfs_site;

prefix "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/gpfs-site.xml}";
"module" = "hdfs/main";


prefix "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/gpfs-site.xml}/contents/gpfs";

"mnt.dir" = "/gpfs/test";
"data.dir" = "hadoop_data";
"storage.type" = "shared";
"replica.enforced" = "gpfs";

prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/core-site.xml}/contents";

'fs/defaultFS' = dict(
    'format', 'hdfs',
    'host', 'storage2204.shuppet.os',
#    'port', 9000,
);

prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/hdfs-site.xml}/contents/dfs";

'datanode/handler.count' = 40;
'datanode/max.transfer.threads' = 8192;
'namenode/handler.count' = 400;

#"/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/slaves}/contents" = list('localhost', 'remotehost');
