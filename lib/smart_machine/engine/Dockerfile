FROM ruby:2.7.0-alpine3.11
LABEL maintainer="Gaurav Goel <gaurav@timeboard.me>"

# User
# --- Fix to change docker gid to 998 (if it is in use) so that addgroup is free to create a group with docker gid.
ARG USER_NAME
ARG USER_UID
ARG DOCKER_GID
ARG DOCKER_GNAME
RUN sed -i "s/$DOCKER_GID/998/" /etc/group && \
	adduser --disabled-password --gecos "" --uid "$USER_UID" "$USER_NAME" && \
	addgroup --gid "$DOCKER_GID" "$DOCKER_GNAME" && adduser "$USER_NAME" "$DOCKER_GNAME"

# Essentials
RUN apk add --update build-base && \
	apk add --update xz && \
	apk add --update docker && \
	apk add --update git && \
	apk add --update rsync && \
    rm -rf /var/cache/apk/*

# smartmachine gem
ARG SMARTMACHINE_VERSION
COPY ./smartmachine-$SMARTMACHINE_VERSION.gem ./smartmachine-$SMARTMACHINE_VERSION.gem
RUN gem install --no-document ./smartmachine-$SMARTMACHINE_VERSION.gem && \
	rm ./smartmachine-$SMARTMACHINE_VERSION.gem

# smartmachine master key
ARG SMARTMACHINE_MASTER_KEY
ENV SMARTMACHINE_MASTER_KEY=$SMARTMACHINE_MASTER_KEY
