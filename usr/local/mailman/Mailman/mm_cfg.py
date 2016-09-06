# -*- python -*-

# Copyright (C) 1998,1999,2000,2001,2002 by the Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

"""This module contains your site-specific settings.

From a brand new distribution it should be copied to mm_cfg.py.  If you
already have an mm_cfg.py, be careful to add in only the new settings you
want.  Mailman's installation procedure will never overwrite your mm_cfg.py
file.

The complete set of distributed defaults, with documentation, are in the file
Defaults.py.  In mm_cfg.py, override only those you want to change, after the

  from Defaults import *

line (see below).

Note that these are just default settings; many can be overridden via the
administrator and user interfaces on a per-list or per-user basis.

Also note that many of these settings will not be effective until Mailman
is restarted.  Thus, you should always restart Mailman after changing this
file.

Further, settings which relate to a list's host_name and web_page_url only
affect lists created after the change.  For existing lists, see the FAQ at
<http://wiki.list.org/x/mIA9>.

"""

###############################################
# Here's where we get the distributed defaults.

from Defaults import *

##################################################
# Put YOUR site-specific settings below this line.

#-------------------------------------------------------------
# If you change these, you have to configure your http server
# accordingly (Alias and ScriptAlias directives in most httpds)
DEFAULT_URL_PATTERN = 'https://%s/'

#-------------------------------------------------------------
# Default domain for email addresses of newly created MLs
DEFAULT_EMAIL_HOST  = 'lists.foo.com'
#-------------------------------------------------------------
# Default host for web interface of newly created MLs
DEFAULT_URL_HOST    = 'lists.foo.com'
#-------------------------------------------------------------
# Required when setting any of its arguments.
add_virtualhost(DEFAULT_URL_HOST, DEFAULT_EMAIL_HOST)

#-------------------------------------------------------------
# Unset send_reminders on newly created lists
DEFAULT_SEND_REMINDERS = No

#-------------------------------------------------------------
# Allow list owners to delete their own lists
OWNERS_CAN_DELETE_THEIR_OWN_LISTS = Yes

#-------------------------------------------------------------
# Uncomment this if you configured your MTA such that it
# automatically recognizes newly created lists.
# (see /usr/local/mailman/bin/postfix-to-mailman.py)
MTA = None   # Misnomer, suppresses alias output on newlist

#-------------------------------------------------------------
# Additional configuration for postfix-to-mailman.py
POSTFIX_STYLE_VIRTUAL_DOMAINS = ['lists.foo.com']
FREEBSD_LISTMASTER = 'admin@foo.com' # Alias for postmaster, abuse and mailer-daemon

#-------------------------------------------------------------
# Uncomment if you use Postfix virtual domains (but not
# postfix-to-mailman.py).
# MTA = 'Postfix'

# Note - if you're looking for something that is imported from mm_cfg, but you
# didn't find it above, it's probably in /usr/local/mailman/Mailman/Defaults.py.

