#include </home/arch/.asdf/installs/erlang/24.2.1/usr/include/erl_nif.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Compute the product of two matrices
void matrix_product(int a_rows, int a_cols, int b_cols, int p, uint16_t **A, uint16_t **B, uint16_t **C) {
    for (int i = 0; i < a_rows; i++) {
        for (int j = 0; j < b_cols; j++) {
            C[i][j] = 0;
            for (int k = 0; k < a_cols; k++) {
                C[i][j] = (C[i][j] + A[i][k] * B[k][j]) % p;
            }
            //printf("[Loop] C[%d][%d] assigned: ######=====> %d <=====######", i, j, C[i][j]);
        }
    }
}

static ERL_NIF_TERM matrix_product_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    // Extract the arguments from the Erlang terms
    int a_rows, a_cols, b_cols, p;
    ErlNifBinary a_bin, b_bin;
    if (!enif_get_int(env, argv[0], &a_rows) ||
        !enif_get_int(env, argv[1], &a_cols) ||
        !enif_get_int(env, argv[2], &b_cols) ||
        !enif_get_int(env, argv[3], &p) ||
        !enif_inspect_binary(env, argv[4], &a_bin) ||
        !enif_inspect_binary(env, argv[5], &b_bin)) {
        return enif_make_badarg(env);
    }
    //printf("[Argv] Arguments:\n\ta_rows: %d, a_cols: %d, b_cols: %d, p: %d\n", a_rows, a_cols, b_cols, p);
    // Convert the binary data to pointers to matrices
    uint16_t **A = malloc(sizeof(uint16_t*) * (a_rows * a_cols));
    uint16_t **B = malloc(sizeof(uint16_t*) * (a_cols * b_cols));
    uint16_t **C = malloc(sizeof(uint16_t*) * (a_rows * b_cols));
    //printf("[Malloc] Arrays allocated [A, B, C]");
    for (int i = 0; i < a_rows; i++) {
        //printf("[Loop A] i: %d\n", i);
        A[i] = malloc(sizeof(uint16_t) * a_cols);
        C[i] = malloc(sizeof(uint16_t) * b_cols);
        for (int j = 0; j < a_cols; j++) {
            //printf("[Loop 1] j: %d", j);
            int offset = 2 * (i * a_cols + j);
            A[i][j] = (uint16_t) a_bin.data[offset] * 256 + (uint16_t) a_bin.data[offset + 1];
            //printf("[Loop 1] A[%d][%d] assigned: ######=====> %d <=====######", i, j, A[i][j]);
        }
    }
    for (int i = 0; i < a_cols; i++) {
        //printf("[Loop B] i: %d\n", i);
        B[i] = malloc(sizeof(uint16_t) * b_cols);
        for (int j = 0; j < b_cols; j++) {
            //printf("[Loop 2] j: %d", j);
            int offset = 2 * (i * b_cols + j);
            B[i][j] = b_bin.data[offset] * 256 + (uint16_t) b_bin.data[offset + 1];
            //printf("[Loop 2] B[%d][%d] assigned: ######=====> %d <=====######", i, j, B[i][j]);//&A[i][j]);
        }
    }

    // Call the matrix_product function
    //printf("[Call] Calling matrix_product\n");
    matrix_product(a_rows, a_cols, b_cols, p, A, B, C);

    uint16_t* data = (uint16_t*) malloc(sizeof(uint16_t) * a_rows * b_cols);

    for (int i = 0; i< a_rows; i++) {
        for (int j = 0; j < b_cols; j++) {
            //printf("Saving C[%d][%d] = ----====> %d <====----", i, j, C[i][j]);
            data[i * b_cols + j] = C[i][j];
        }
    }

    ErlNifBinary binary;
    enif_alloc_binary(sizeof(uint16_t) * a_rows * b_cols, &binary);
    memcpy(binary.data, data, sizeof(uint16_t) * a_rows * b_cols);

    ERL_NIF_TERM result = enif_make_binary(env, &binary);

    //Free the memory
    //printf("[Free] Freeing memory");
    free(A);
    free(B);
    free(C);
    free(data);
    enif_release_binary(&binary);

    // Return the binary to Elixir
    //printf("[Return] Returning result\n");
    return result;
}

static ErlNifFunc nif_funcs[] = {
    {"matrix_product", 6, matrix_product_nif}
};

static int
upgrade(ErlNifEnv* env, void** priv_data, void** old_priv_data, ERL_NIF_TERM load_info) {
    return 0;
}

ERL_NIF_INIT(Elixir.LAP2.Math.Matrix, nif_funcs, NULL, NULL, upgrade, NULL);
