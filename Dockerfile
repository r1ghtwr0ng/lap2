FROM elixir:1.14-slim

# Use bash as the default shell
SHELL ["/bin/bash", "-c"]

# Copy the application files
WORKDIR /app
ADD lib /app/lib
ADD config /app/config
ADD native /app/native
ADD priv /app/priv
ADD specs /app/specs
COPY mix.exs /app/mix.exs
COPY .iex.exs /app/.iex.exs

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
ENTRYPOINT [ "iex", "-S", "mix" ]