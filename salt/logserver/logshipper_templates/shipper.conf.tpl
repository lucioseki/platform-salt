{%- set logdest = salt['pnda.ip_addresses']('logserver')[0] -%}
input {
{% if grains['os'] in ('RedHat', 'CentOS') %}
   journald {
          path => '/run/log/journal'
          sincedb_path => "/opt/pnda/logstash/sincedb/db2"
          add_field => {"path" => "journald"}
          lowercase => true
   }
{% elif grains['os'] == 'Ubuntu' %}
   file {
          path => ["/var/log/upstart/kafka.log"]
          add_field => {"source" => "kafka"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   file {
          path => ["/var/log/upstart/gobblin.log"]
          add_field => {"source" => "gobblin"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   file {
          path => ["/var/log/upstart/deployment-manager.log"]
          add_field => {"source" => "deployment-manager"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   file {
          path => ["/var/log/upstart/package-repository.log"]
          add_field => {"source" => "package-repository"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   file {
          path => ["/var/log/upstart/jupyterhub.log"]
          add_field => {"source" => "jupyter"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
{% endif %}
   file {
          path => ["/var/log/pnda/kafka/server.log",
                   "/var/log/pnda/kafka/controller.log"]
          add_field => {"source" => "kafka"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   file {
          path => ["/var/log/pnda/zookeeper/zookeeper.log"]
          add_field => {"source" => "zookeeper"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   file {
          path => ["/var/log/pnda/gobblin/*.log"]
          add_field => {"source" => "gobblin"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   file {
          path => ["/var/log/salt/minion",
                   "/var/log/pnda/hadoop_setup.log"]
          add_field => {"source" => "provisioning"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   file {
          path => ["/var/log/pnda/opentsdb/opentsdb.log"]
          add_field => {"source" => "opentsdb"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   file {
          path => ["/var/log/grafana/grafana.log"]
          add_field => {"source" => "grafana"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   file {
          path => ["/var/log/pnda/hadoop-yarn/container/application_*/container_*/stdout",
                   "/var/log/pnda/hadoop-yarn/container/application_*/container_*/stderr",
                   "/var/log/pnda/hadoop-yarn/container/application_*/container_*/syslog",
                   "/var/log/pnda/hadoop-yarn/container/application_*/container_*/spark.log"]
          add_field => {"source" => "yarn"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          discover_interval => "5"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }

   {% for log_section in pillar['log-shipper-patterns'] %}
   file {
          {%- set log_section_paths = pillar['log-shipper-patterns'][log_section] -%}
          path => [{{ log_section_paths|join(',') }}]
          add_field => {"source" => "{{ log_section }}"}
          sincedb_path => "{{ install_dir }}/logstash/sincedb/db"
          codec => multiline {
            pattern => "^%{TIMESTAMP_ISO8601}"
            negate => true
            what => "previous"
          }
   }
   {% endfor %}
}

filter {
   if [_systemd_unit] {
       if [_systemd_unit] == "kafka.service" {
           mutate {add_field => {"source" => "kafka"}}
       }
       else if [_systemd_unit] == "gobblin.service" {
           mutate {add_field => {"source" => "gobblin"}}
       }
       else if [_systemd_unit] == "deployment-manager.service" {
           mutate {add_field => {"source" => "deployment-manager"}}
       }
       else if [_systemd_unit] == "package-repository.service" {
           mutate {add_field => {"source" => "package-repository"}}
       }
       else if [_systemd_unit] == "jupyterhub.service" {
           mutate {add_field => {"source" => "jupyterhub"}}
       }
       else {
           drop { }
       }
   }

   grok {
       match => { "path" => "/var/log/pnda/hadoop-yarn/container/%{DATA:applicationId}/%{DATA:containerId}/%{GREEDYDATA:logtype}" }
   }

}

output {
   redis { host => "{{ logdest }}" data_type => "channel" key => "logstash-%{+yyyy.MM.dd.HH}" }
}
