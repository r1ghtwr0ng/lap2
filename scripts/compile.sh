#!/bin/bash

# This script is used to fetch deps and compile the project.
echo "[+] Getting deps..."
mix deps.get
mix deps.compile
echo "[+] Compiling Elixir code..."
mix compile

# Compile NIFs
echo "[+] Compiling NIFs..."
gcc -o ./lib/nifs/matrix_product.so -fPIC -shared ./lib/nifs/matrix_product.c

echo "[+] Done!"