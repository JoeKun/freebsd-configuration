<?php

/* Local configuration for Roundcube Webmail */

$config['db_dsnw'] = 'pgsql://roundcube:RoundCubePassword@localhost/roundcube';

$config['default_host'] = 'localhost';

$config['smtp_server'] = 'localhost';

$config['support_url'] = 'mailto:admin@foo.com';

$config['ip_check'] = true;

$config['des_key'] = 'b+ITLBama21h%E5pGzEffAer';

$config['product_name'] = 'Webmail';

$config['plugins'] = array('attachment_reminder', 'emoticons', 'hide_blockquote', 'markasjunk', 'password');

$config['language'] = 'en_US';

$config['spellcheck_engine'] = 'atd';

$config['htmleditor'] = 2;

$config['draft_autosave'] = 60;

$config['mime_param_folding'] = 0;

$config['mime_types'] = '/usr/local/www/roundcube/config/mime.types';

$config['enable_installer'] = false;

