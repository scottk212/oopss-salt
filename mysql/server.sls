
##############################################################################
# oopss-salt
# Description : Oopss infrastructure files using SaltStack
# URL : https://github.com/oopss/oopss-salt
# Copyright 2013-2016 Oopss.org <team@oopss.org>
##############################################################################

include:
    - oopss.mysql

oopss_mysql_server_pkg:
    pkg:
        - installed
        - names:
            - mysql-server
            - python-mysqldb
            - mytop
            - mysqltuner
            - percona-toolkit

oopss_mysql_server_service:
    service:
        - name: mysql
        - running
        - require:
            - pkg: oopss_mysql_server_pkg

oopss_mysql_server_socket_perm:
    file:
        - name: /var/run/mysqld/
        - directory
        - user: mysql
        - group: mysql
        - mode: 700
        - require:
            - pkg: oopss_mysql_server_pkg

oopss_mysql_server_config_base:
    file:
        - managed
        - name: /etc/mysql/conf.d/local.cnf
        - source: salt://oopss/mysql/files/local.cnf
        - template: jinja
        - user: root
        - group: adm
        - mode: 440
        - watch_in:
            - service: oopss_mysql_server_service

oopss_mysql_server_rootconfig:
    file:
        - symlink
        - name: /root/.my.cnf
        - target: /etc/mysql/debian.cnf
        - require:
            - pkg: oopss_mysql_server_pkg

oopss_mysql_server_cleancmd:
    cmd:
        - wait
        - names:
            - mysql -e "delete from user where user = '' or user = 'root'; flush privileges;" mysql
        - watch:
            - pkg: oopss_mysql_server_pkg

oopss_mysql_server_dumpscript:
    {% if salt['pillar.get']('oopss:mysql:server:daily_dump') %}
    file:
        - managed
        - name: /etc/cron.daily/dump_mysql
        - source: salt://oopss/mysql/files/dump_mysql
        - user: root
        - group: root
        - mode: 700
    {% else %}
    file:
        - absent
        - name: /etc/cron.daily/dump_mysql
    {% endif %}

{% for user, prop in salt['pillar.get']('oopss:mysql:server:users', {}).iteritems() %}
oopss_mysql_users_{{ user }}:
    mysql_user:
        - present
        - name: {{ user }}
        - host: '%'
        {%- if prop.get('active', true) %}
        - password_hash: '{{ prop.password }}'
        {%- else %}
        - password_hash: '*XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        {%- endif %}
        - require:
            - pkg: oopss_mysql_server_pkg

oopss_mysql_users_db_{{ user }}:
    mysql_database:
        - present
        - name: {{ user }}
        - require:
            - mysql_user: oopss_mysql_users_{{ user }}

oopss_mysql_users_grant_{{ user }}:
    mysql_grants:
      {%- if prop.get('active', true) %}
        - present
      {%- else %}
        - absent
      {% endif %}
        - grant: all privileges
        - database : {{ user }}.*
        - user : {{ user }}
        - host: '%'
        - require:
            - mysql_database: oopss_mysql_users_db_{{ user }}
{% endfor %}

