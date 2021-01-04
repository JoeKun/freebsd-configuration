--[[
Copyright © 2021 Joel Lopes Da Silva. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]--

local exports = {}

local BAYES_CLASSIFIER_KIND = {
    GLOBAL = "global", 
    PER_USER = "per_user", 
}

local can_learn_with_bayes_classifier_kind = function(bayes_classifier_kind)
    return function(task, is_spam, is_unlearn)
        local can_learn = false
        local reason = nil
        
        local original_to_header_name = "X-Original-To"
        local original_to_header_value = task:get_header(original_to_header_name)
        if original_to_header_value and bayes_classifier_kind == BAYES_CLASSIFIER_KIND.GLOBAL then
            can_learn = false
            reason = string.format("skip learning mail with %s header using %s bayes classifier", original_to_header_name, bayes_classifier_kind)
        elseif original_to_header_value == nil and bayes_classifier_kind == BAYES_CLASSIFIER_KIND.PER_USER then
            can_learn = false
            reason = string.format("skip learning mail without %s header using %s bayes classifier", original_to_header_name, bayes_classifier_kind)
        else
            local default_learn_condition = require("lua_bayes_learn").can_learn
            can_learn, reason = default_learn_condition(task, is_spam, is_unlearn)
        end
        
        return can_learn, reason
    end
end

exports.can_learn_with_bayes_global_classifier = can_learn_with_bayes_classifier_kind(BAYES_CLASSIFIER_KIND.GLOBAL)
exports.can_learn_with_bayes_per_user_classifier = can_learn_with_bayes_classifier_kind(BAYES_CLASSIFIER_KIND.PER_USER)

return exports