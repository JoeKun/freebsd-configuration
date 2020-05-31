# 
# 10-file-flagged-spam-into-spam-folder.sieve
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

require ["fileinto"];

if header :contains "X-Spam-Flag" "YES" {
    fileinto "Spam";
}

if header :contains "X-Spam" "YES" {
    fileinto "Spam";
}

if header :contains "Subject" ["*** SPAM ***", "***SPAM***"] {
    fileinto "Spam";
}

