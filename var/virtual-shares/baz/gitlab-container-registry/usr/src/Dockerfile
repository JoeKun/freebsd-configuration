# Dockerfile for gitlab-container-registry

# This docker image is meant as a simple copy of the one provided by
# registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry, with the
# important exception that it allows customizing the user ID of the `git` user,
# which could matter in an environment where we want to match the user ID with
# that of an existing `git` user in the host machine.

ARG GITLAB_CONTAINER_REGISTRY_VERSION
ARG GITLAB_USER=git
ARG GITLAB_UID

FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:${GITLAB_CONTAINER_REGISTRY_VERSION}

ARG GITLAB_USER
ARG GITLAB_UID

USER root:root

RUN deluser git \
    && rm -R -f /home/git \
    && adduser --system --disabled-password --no-create-home --home /nonexistent --gecos 'GitLab' --uid ${GITLAB_UID} --group ${GITLAB_USER}

USER ${GITLAB_USER}:${GITLAB_USER}
