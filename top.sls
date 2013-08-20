
# oopss-infra
# Description : Oopss infrastructure files using SaltStack
# URL : https://github.com/oopss/oopss-infra
# Copyright 2013 Oopss.org <team@oopss.org>

base:
    '*':
        - mail.postfix
        - net.ssh.server
        - scm.git
        - sysutils.cron-apt
        - sysutils.locales
        - sysutils.rsyslog
        - sysutils.sudo
        - sysutils.timezone
        - sysutils.users
        - utils.bash
        - utils.screen
        - utils.vim

    'git':
        - match: nodegroup
        - irc.ii
        - scm.git.server

