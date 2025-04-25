//
// Copyright (c) 2022 ZettaScale Technology
//
// This program and the accompanying materials are made available under the
// terms of the Eclipse Public License 2.0 which is available at
// http://www.eclipse.org/legal/epl-2.0, or the Apache License, Version 2.0
// which is available at https://www.apache.org/licenses/LICENSE-2.0.
//
// SPDX-License-Identifier: EPL-2.0 OR Apache-2.0
//
// Contributors:
//   ZettaScale Zenoh Team, <zenoh@zettascale.tech>
//

#include <ctype.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zenoh-pico.h>

#if Z_FEATURE_SUBSCRIPTION == 1

int instance_id = 0;

void data_handler(z_loaned_sample_t *sample, void *ctx) {
    (void)(ctx);
    z_view_string_t keystr;
    z_keyexpr_as_view_string(z_sample_keyexpr(sample), &keystr);
    z_owned_string_t value;
    z_bytes_to_string(z_sample_payload(sample), &value);

    // Check if message is from our instance
    char self_prefix[32];
    snprintf(self_prefix, sizeof(self_prefix), "Pub from Pico %d", instance_id);
    if (strstr(z_string_data(z_loan(value)), self_prefix) == NULL) {
        printf(">> [Subscriber] Received ('%.*s': '%.*s')\n", (int)z_string_len(z_loan(keystr)),
               z_string_data(z_loan(keystr)), (int)z_string_len(z_loan(value)), z_string_data(z_loan(value)));
    }
    z_drop(z_move(value));
}

int main(int argc, char **argv) {
    if(argc > 1) {
        instance_id = atoi(argv[1]);
    } else {
        instance_id = 1;
    }
    char pub_value[256];
    snprintf(pub_value, sizeof(pub_value), "Pub from Pico %d", instance_id);
    (void)(argc);
    (void)(argv);
    const char *keyexpr = "demo/example/**";
    const char *mode = "peer";
    const char *listen = "tcp/0.0.0.0:7447";

    z_owned_config_t config;
    z_config_default(&config);
    zp_config_insert(z_loan_mut(config), Z_CONFIG_MODE_KEY, mode);
    zp_config_insert(z_loan_mut(config), Z_CONFIG_LISTEN_KEY, listen);

    zp_config_insert(z_loan_mut(config), Z_CONFIG_CONNECT_KEY, "tcp/127.0.0.1:7447");
    printf("Opening session...\n");
    z_owned_session_t s;
    if (z_open(&s, z_move(config), NULL) < 0) {
        printf("Unable to open session!\n");
        return -1;
    }

    // Start read and lease tasks for zenoh-pico
    if (zp_start_read_task(z_loan_mut(s), NULL) < 0 || zp_start_lease_task(z_loan_mut(s), NULL) < 0) {
        printf("Unable to start read and lease tasks\n");
        z_session_drop(z_session_move(&s));
        return -1;
    }

    z_owned_closure_sample_t callback;
    z_closure(&callback, data_handler, NULL, NULL);
    printf("Declaring Subscriber on '%s'...\n", keyexpr);
    z_owned_subscriber_t sub;
    z_view_keyexpr_t ke;
    if (z_view_keyexpr_from_str(&ke, keyexpr) < 0) {
        printf("%s is not a valid key expression\n", keyexpr);
        return -1;
    }
    if (z_declare_subscriber(z_loan(s), &sub, z_loan(ke), z_move(callback), NULL) < 0) {
        printf("Unable to declare subscriber.\n");
        return -1;
    }

    printf("Declaring Publisher on '%s'...\n", keyexpr);
    z_owned_publisher_t pub;
    z_view_keyexpr_t ke_pub;
    if (z_view_keyexpr_from_str(&ke_pub, keyexpr) < 0) {
        printf("%s is not a valid key expression for publisher\n", keyexpr);
        return -1;
    }
    if (z_declare_publisher(z_loan(s), &pub, z_loan(ke_pub), NULL) < 0) {
        printf("Unable to declare publisher for key expression!\n");
        return -1;
    }
    printf("Press CTRL-C to quit...\n");
    int idx = 0;
    while (1) {
        Sleep(1000);
        char buf[256];
        snprintf(buf, sizeof(buf), "[%4d] %s", idx, pub_value);
        printf("Putting Data ('%s': '%s')...\n", keyexpr, buf);
        z_owned_bytes_t payload;
        z_bytes_from_str(&payload, buf, NULL, NULL);
        z_publisher_put(z_loan(pub), z_move(payload), NULL);
        idx++;
    }

    z_drop(z_move(sub));

    z_drop(z_move(s));

    return 0;
}
#else
int main(void) {
    printf("ERROR: Zenoh pico was compiled without Z_FEATURE_SUBSCRIPTION but this example requires it.\n");
    return -2;
}
#endif