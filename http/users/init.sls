
##############################################################################
# oopss-salt
# Description : Oopss infrastructure files using SaltStack
# URL : https://github.com/oopss/oopss-salt
# Copyright 2013-2016 Oopss.org <team@oopss.org>
##############################################################################

{% from "oopss/http/map.jinja" import http_config with context %}

{% if salt['pillar.get']('http:web_server', False) == 'oopss.nginx' %}
include:
    - oopss.nginx
{% endif %}

{{ http_config['rootdir'] }}:
    file.directory:
        - user: root
        - group: root
        - mode: 711

# For each user in pillar http:users
{% for user, userinfo in salt['pillar.get']('http:users', {}).iteritems() %}
{% set user_is_active = userinfo.get('is_active', True) %}
# Web user and group
{{ user }}:
    group:
        {%- if user_is_active %}
        - present
        - gid: {{ userinfo['uid'] }}
        - addusers:
            - www-data
        {%- else %}
        - absent
        - require:
            - user: {{ user }}
        {%- endif %}
{% if salt['pillar.get']('http:web_server', False) == 'oopss.nginx' %}
        - watch_in:
            - service: oopss_nginx_service
{% endif %}

    user:
        {%- if user_is_active %}
        - present
        - uid: {{ userinfo['uid'] }}
        - gid: {{ userinfo['uid'] }}
        - password: '{{ userinfo['password'] }}'
        - home: "{{ http_config['rootdir'] }}/{{ user }}"
        - shell: "/bin/bash"
        - createhome: False
        - fullname: ""
        - groups:
            - sshusers
{% if userinfo['additional_groups'] is defined %}
{% for group in userinfo['additional_groups'] %}
            - {{ group }}
{% endfor %}
{% endif %}
        - require:
            - group: {{ user }}
{% if userinfo['additional_groups'] is defined %}
{% for group in userinfo['additional_groups'] %}
            - group: {{ group }}
{% endfor %}
{% endif %}
        {%- else %}
        - absent
        {%- endif %}

{% if user_is_active %}

# Web user home directory
{{ http_config['rootdir'] }}/{{ user }}:
    file.directory:
        - mode: 750
        - user: {{ user }}
        - group: {{ user }}
        - require:
            - user: {{ user }}

{% endif %}

{% if userinfo['root_paths'] is defined %}

{% if user_is_active %}

# Socket directory
{{ http_config['rootdir'] }}/{{ user }}/.sock:
    file.directory:
        - mode: 710
        - user: {{ user }}
        - group: {{ user }}
        - require:
            - file: {{ http_config['rootdir'] }}/{{ user }}

# SSH directory
{{ http_config['rootdir'] }}/{{ user }}/.ssh:
    file.directory:
        - mode: 700
        - user: {{ user }}
        - group: {{ user }}
        - require:
            - file: {{ http_config['rootdir'] }}/{{ user }}

# SSH authorized_keys
{{ http_config['rootdir'] }}/{{ user }}/.ssh/authorized_keys:
    file.managed:
        - mode: 600
        - replace: False
        - user: {{ user }}
        - group: {{ user }}
        - require:
            - file: {{ http_config['rootdir'] }}/{{ user }}/.ssh

# Log directory
{{ http_config['rootdir'] }}/{{ user }}/log:
    file.directory:
        - mode: 750
        - user: root
        - group: {{ user }}
        - require:
            - user: {{ user }}
            - file: {{ http_config['rootdir'] }}/{{ user }}

{% endif %} {# user_is_active #}

# For each root_path
{% for root_path, root_pathinfo in userinfo.get('root_paths', {}).iteritems() %}

{% set rootpath_is_active = root_pathinfo.get('is_active', True) %}

{% if user_is_active %}
# Root path
{{ http_config['rootdir'] }}/{{ user }}/{{ root_path }}:
    file.directory:
        - user: {{ user }}
        - group: {{ user }}
        - mode: 750
        - require:
            - file: {{ http_config['rootdir'] }}/{{ user }}

# Web server access file
{{ http_config['rootdir'] }}/{{ user }}/log/{{ root_path }}-access.log:
    file.managed:
        - mode: 640
        - replace: False
        - user: www-data
        - group: {{ user }}
        - require:
            - user: {{ user }}
            - file: {{ http_config['rootdir'] }}/{{ user }}/log

# Web server error file
{{ http_config['rootdir'] }}/{{ user }}/log/{{ root_path }}-error.log:
    file.managed:
        - mode: 640
        - replace: False
        - user: www-data
        - group: {{ user }}
        - require:
            - user: {{ user }}
            - file: {{ http_config['rootdir'] }}/{{ user }}/log

{% endif %} {# user_is_active #}
# Logrotate config
/etc/logrotate.d/www-{{ user }}-{{ root_path }}:
    file:
        {%- if user_is_active and rootpath_is_active %}
        - managed
        - mode: 400
        - user: root
        - group: root
        - source: salt://oopss/http/users/logrotate
        - template: jinja
        - context:
            user: {{ user }}
            root_path: {{ root_path }}
        - require:
            - user: {{ user }}
        {%- else %}
        - absent
        {%- endif %}

# If using Nginx
{% set file_is_active = rootpath_is_active or root_pathinfo.get('proxy_to', False) %}
{% if salt['pillar.get']('http:web_server', False) == 'oopss.nginx' %}
/etc/nginx/sites-available/{{ user }}-{{ root_path }}:
    file:
        {%- if user_is_active and file_is_active %}
        - managed
        - user: root
        - group: adm
        - mode: 440
        {% if root_pathinfo.get('proxy_to', False) %}
        - source: salt://oopss/http/users/files/vhost_proxy
        {% else %}
        - source: salt://oopss/http/users/files/vhost
        {% endif %}
        - template: jinja
        - context:
            user: {{ user }}
            root_path: {{ root_path }}
            root_pathinfo: {{ root_pathinfo }}
            socket: {{ http_config['rootdir'] }}/{{ user }}/.sock/{{ root_path }}.sock
            http_auth_file: {{ root_pathinfo.get('http_auth_file', http_config['rootdir'] + "/" + user + "/.htpasswd") }}

        - require:
            - pkg: oopss_nginx_pkg
            - file: {{ http_config['rootdir'] }}/{{ user }}/{{ root_path }}
            - file: {{ http_config['rootdir'] }}/{{ user }}/log/{{ root_path }}-access.log
            - file: {{ http_config['rootdir'] }}/{{ user }}/log/{{ root_path }}-error.log
        {%- else %}
        - absent
        {%- endif %}
        - watch_in:
            - service: oopss_nginx_service

/etc/nginx/sites-enabled/{{ user }}-{{ root_path }}:
    file:
        {%- if user_is_active and file_is_active %}
        - symlink
        - target: /etc/nginx/sites-available/{{ user }}-{{ root_path }}
        - force: True
        - require:
            - file: /etc/nginx/sites-available/{{ user }}-{{ root_path }}
        {%- else %}
        - absent
        {%- endif %}
        - watch_in:
            - service: oopss_nginx_service
{% endif %}

{% endfor %}
{% endif %}
{% endfor %}

