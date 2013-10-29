
##############################################################################
# oopss-infra
# Description : Oopss infrastructure files using SaltStack
# URL : https://github.com/oopss/oopss-infra
# Copyright 2013 Oopss.org <team@oopss.org>
##############################################################################

sshusers:
    group.present:
        - system: True

{% if pillar['users'] is defined %}
{% for user, userinfo in pillar['users'].iteritems() %}
{{ user }}:
    group.present:
        - gid: {{ userinfo['uid'] }}

    user.present:
        - uid: {{ userinfo['uid'] }}
        - gid: {{ userinfo['uid'] }}
        - home: "/home/{{ user }}"
        - createhome: False
        - shell: "/bin/bash"
        - fullname: {{ userinfo['fullname'] }}
        {% if userinfo['password'] is defined %}
        - password: {{ userinfo['password'] }}
        {% endif %}
        - groups:
            - sshusers
        {% if userinfo['sudoer'] is defined %}
        {% if userinfo['sudoer'] == True %}
            - sudo
        {% endif %}
        {% endif %}
        {% if userinfo['adm'] is defined %}
        {% if userinfo['adm'] == True %}
            - adm
        {% endif %}
        {% endif %}
        - require:
            - group: {{ user }}
            - group: sshusers

{% if userinfo['ssh_auth'] is defined %}
    ssh_auth:
        - present
        - user: {{ user }}
        - names: {{ userinfo['ssh_auth'] }}
        - require:
            - file: /home/{{ user }}
{% endif %}

/home/{{ user }}:
    file.directory:
        - mode: 700
        - user: {{ user }}
        - group: {{ user }}
        - makedirs: True
        - require:
            - user: {{ user }}
{% endfor %}
{% endif %}


##############################################################################
# Forbid users to change manually their informations in /etc/{passwd,shadow}
##############################################################################

suid-remove:
    file.managed:
        - names:
            - /usr/bin/chfn
            - /usr/bin/chsh
            - /usr/bin/passwd
        - mode: 0755

