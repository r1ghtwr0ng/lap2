FROM elixir:1.14-slim

# Use bash as the default shell
SHELL ["/bin/bash", "-c"]

# Copy the application files
WORKDIR /app
COPY .iex.exs /app/.iex.exs
COPY config /app/config
COPY lib /app/lib
COPY native /app/native
COPY priv /app/priv
COPY scripts /app/scripts
COPY specs /app/specs
COPY test /app/test
COPY LICENSE /app/LICENSE
COPY mix.exs /app/mix.exs
COPY mix.lock /app/mix.lock
COPY README.md /app/README.md

# Install Debian Dependencies
RUN apt update && apt upgrade -y && \
    apt install make cmake gcc -y && \
    apt install bash curl protobuf-compiler -y

# Install Rust
RUN curl -proto '=https' -tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Elixir dependencies
RUN source $HOME/.cargo/env && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile

# Program entrypoint for debugging
#ENTRYPOINT [ "bash" ]