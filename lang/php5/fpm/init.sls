
##############################################################################
# oopss-salt
# Description : Oopss infrastructure files using SaltStack
# URL : https://github.com/oopss/oopss-salt
# Copyright 2013-2016 Oopss.org <team@oopss.org>
##############################################################################

include:
    - oopss.lang.php5

php5-fpm:
    pkg:
        - installed

    service:
        - running
        - require:
            - pkg: php5-fpm
        - watch:
            - file: /etc/php5/fpm/conf.d/local.ini
            - file: /etc/php5/fpm/pool.d/www.conf
            - file: /etc/default/php5-fpm

/etc/php5/fpm/conf.d/local.ini:
    file.managed:
        - source: salt://oopss/lang/php5/fpm/local.ini
        - user: root
        - group: root
        - mode: 400

/etc/php5/fpm/pool.d/www.conf:
    file.absent

/etc/default/php5-fpm:
    file.managed:
        - source: salt://oopss/lang/php5/fpm/init_default
        - user: root
        - group: root
        - mode: 400

{% for user, userinfo in salt['pillar.get']('http:users', {}).iteritems() %}
{% set user_is_active = userinfo.get('is_active', True) %}

{% for root_path, root_pathinfo in userinfo.get('root_paths', {}).iteritems() %}
{% if root_pathinfo.get('type', False) in ['php', 'php_redirect_to_index', 'wordpress_multisite'] %}
/etc/php5/fpm/pool.d/{{ user }}-{{ root_path }}.conf:
    file:
        {%- if user_is_active and root_pathinfo.get('is_active', True) %}
        - managed
        - user: root
        - group: adm
        - mode: 440
        - source: salt://oopss/lang/php5/fpm/config
        - template: jinja
        - context:
            user: {{ user }}
            root_path: {{ root_path }}
            max_children: {{ salt['pillar.get']('lang:php5:fpm:max_children', '10') }}
        - require:
            - pkg: php5-fpm
        {%- else %}
        - absent
        {%- endif %}
        - watch_in:
            - service: php5-fpm
{% endif %}
{% endfor %}
{% endfor %}

