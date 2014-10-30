
##############################################################################
# oopss-infra
# Description : Oopss infrastructure files using SaltStack
# URL : https://github.com/oopss/oopss-infra
# Copyright 2013-2014 Oopss.org <team@oopss.org>
##############################################################################

/etc/motd:
    file.managed:
        - user: root
        - group: root
        - mode: 444
        # To define a multiline pillar value, add a pipe symbol (|) after the
        # pillar key, and put the content below, indented with two spaces
        # relatively to the pillar key.
        # Example :
        # pillar_key1:
        #     pillar_key2: |
        #       multiline
        #       pillar
        #       value
        # Warning : the first caracter of the pillar value ("m" in the
        # example) should NOT be a space caracter !
        - contents_pillar: base:motd

