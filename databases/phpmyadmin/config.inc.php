<?php

# Managed by Salt

// Load secret generated on postinst
include('/var/lib/phpmyadmin/blowfish_secret.inc.php');

/*
 * Directories for saving/loading files from server
 */
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';

/*
 * Hide warning about unconfigured configuration storage.
 */
$cfg['PmaNoRelation_DisableWarning'] = true;

$cfg['Servers'][1]['host'] = '{{ salt['pillar.get']('databases:phpmyadmin:db_server', '127.0.0.1') }}';

