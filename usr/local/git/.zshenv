# ~/.zshenv: Personal environment variables for zsh

# Login greeting name.
export LOGIN_GREETING_NAME="GitLab"

# Silent login.
export ACCEPT_MESSAGES_FROM_OTHER_USERS_DISABLED=1
export ECHO_SYSTEM_INFORMATION_UPON_LOGIN_DISABLED=1
export LOGIN_GREETING_DISABLED=1
export FORTUNE_UPON_LOGIN_DISABLED=1

# Select desired ruby version using chruby.
chruby_initialization_script_file_path="/usr/local/share/chruby/chruby.sh"
gitlab_ruby_version_file_path="${HOME}/gitlab/.ruby-version"
if [[ -r "${chruby_initialization_script_file_path}" ]] && [[ -r "${gitlab_ruby_version_file_path}" ]]
then
    source "${chruby_initialization_script_file_path}"
    gitlab_ruby_version=$(cat "${gitlab_ruby_version_file_path}")
    matching_ruby_version_entry_in_chruby=$(chruby | sed "s/^[ \*]*//" | grep "ruby-${gitlab_ruby_version}")
    if [[ -n "${matching_ruby_version_entry_in_chruby}" ]]
    then
        chruby "${matching_ruby_version_entry_in_chruby}"
    fi
fi

