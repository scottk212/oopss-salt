
##############################################################################
# oopss-salt
# Description : Oopss infrastructure files using SaltStack
# URL : https://github.com/oopss/oopss-salt
# Copyright 2013-2016 Oopss.org <team@oopss.org>
##############################################################################

{% from "oopss/databases/postgresql/map.jinja" import postgresql with context %}

include:
    - oopss.databases.postgresql

postgresql-{{ postgresql.version }}:
    pkg.installed

postgresql:
    service:
        - running
        - reload: True
        - require:
            - pkg: postgresql-{{ postgresql.version }}
        - watch:
            - file: /etc/postgresql/{{ postgresql.version }}/main/pg_hba.conf

/etc/postgresql/{{ postgresql.version }}/main/pg_hba.conf:
    file.managed:
        - template: jinja
        - user: postgres
        - group: adm
        - mode: 440
        - source: salt://oopss/databases/postgresql/pg_hba.conf
        - require:
            - pkg: postgresql-{{ postgresql.version }}
        - context:
            mon_user: {{ salt['pillar.get']('databases:postgresql:mon_user', False) }}
            listen_on: {{ salt['pillar.get']('databases:postgresql:listen_on', '127.0.0.1/32') }}


##############################################################################
# Read pillar databases:postgresql:users then create users and databases
##############################################################################

{% for user, prop in salt['pillar.get']('databases:postgresql:users', {}).iteritems() %}
postgresql-user-{{ user }}:
    postgres_user:
        - present
        - name: {{ user }}
        # Password should be provided in Pillar as the result of
        # MD5(clearpassword+username).
        # WARNING: Until now, the postgres_user state does not support user
        # modification. So, password modification won't work.
      {%- if prop.get('active', true) %}
        - password: 'md5{{ prop.password }}'
      {%- else %}
        - password: 'md5xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
      {%- endif %}
        - encrypted: False
        - require:
            - pkg: postgresql-{{ postgresql.version }}

postgresql-db-{{ user }}:
    postgres_database:
        - present
        - name: {{ user }}
        - owner: {{ user }}
        - encoding: 'UTF8'
        - template: 'template0'
        - require:
            - postgres_user: postgresql-user-{{ user }}
{% endfor %}

/etc/cron.daily/dump_pgsql:
    {% if salt['pillar.get']('databases:postgresql:daily_dump') %}
    file.managed:
        - source: salt://oopss/databases/postgresql/dump_pgsql
        - user: root
        - group: root
        - mode: 700
    {% else %}
    file.absent
    {% endif %}

