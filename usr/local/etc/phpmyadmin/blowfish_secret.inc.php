<?php
/**
 * This is needed for cookie based authentication to encrypt password in cookie.
 *
 * Set this value to a randomly generated password of 32 characters, preferably.
 * You may use the following command to generate such a random password:
 *
 *     pwgen --capitalize --numerals --symbols --secure -1 32 1
 *
 */
$cfg['blowfish_secret'] = '';
