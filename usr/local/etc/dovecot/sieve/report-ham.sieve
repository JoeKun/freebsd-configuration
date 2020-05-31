# 
# report-ham.sieve
# 
# Created by Joel Lopes Da Silva on 5/17/20.
# Copyright © 2020 Joel Lopes Da Silva. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#       http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require ["vnd.dovecot.pipe", "copy", "imapsieve", "environment", "variables"];

if environment :matches "imap.mailbox" "*" {
    set "mailbox" "${1}";
}

if string "${mailbox}" "Trash" {
    stop;
}

if environment :matches "imap.email" "*" {
    set "email" "${1}";
}

if header :matches "message-id" "*" {
    set "message_identifier" "${1}";
}

pipe :copy "train-rspamd" [ "ham", "${email}", "${message_identifier}" ];

