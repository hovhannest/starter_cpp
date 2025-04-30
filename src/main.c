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
#include <windows.h>
#include <zenoh-pico.h>

volatile int running = 1;

BOOL WINAPI ConsoleHandler(DWORD signal) {
    if (signal == CTRL_C_EVENT) {
        printf("\nReceived CTRL+C, shutting down...\n");
        running = 0;
        return TRUE;
    }
    return FALSE;
}

#if Z_FEATURE_SUBSCRIPTION == 1

int instance_id = 0;

void data_handler(z_loaned_sample_t *sample, void *ctx) {
    (void)(ctx);
    z_view_string_t keystr;
    if (z_keyexpr_as_view_string(z_sample_keyexpr(sample), &keystr) < 0) {
        printf("Error: Failed to convert keyexpr to string\n");
        return;
    }
    
    z_owned_string_t value;
    if (z_bytes_to_string(z_sample_payload(sample), &value) < 0) {
        printf("Error: Failed to convert payload to string\n");
        return;
    }

    // Extract source instance ID from the message
    const char *msg_data = z_string_data(z_loan(value));
    int source_id = -1;
    const char *prefix = "Pub from Pico ";
    const char *id_start = strstr(msg_data, prefix);
    
    if (id_start != NULL) {
        if (sscanf(id_start + strlen(prefix), "%d", &source_id) != 1) {
            source_id = -1;  // Reset if sscanf fails
        }
    }
    
    // Skip if we couldn't extract a valid source ID
    if (source_id < 0) {
        z_drop(z_move(value));
        return;
    }

    // Check if message is from our instance (avoid self-messages)
    if (source_id != instance_id) {
        printf(">> [Subscriber] Received ('%.*s': '%.*s')\n",
               (int)z_string_len(z_loan(keystr)),
               z_string_data(z_loan(keystr)),
               (int)z_string_len(z_loan(value)),
               z_string_data(z_loan(value)));
    }
    z_drop(z_move(value));
}

int main(int argc, char **argv) {
    if (argc > 1) {
        instance_id = atoi(argv[1]);
    } else {
        instance_id = 1;
    }
    char pub_value[256];
    snprintf(pub_value, sizeof(pub_value), "Pub from Pico %d", instance_id);
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
    if (!SetConsoleCtrlHandler(ConsoleHandler, TRUE)) {
        printf("ERROR: Could not set control handler\n");
        return 1;
    }
    
    while (running) {
        Sleep(1000);
        char buf[256];
        snprintf(buf, sizeof(buf), "[%4d] %s", idx, pub_value);
        printf("Putting Data ('%s': '%s')...\n", keyexpr, buf);
        
        z_owned_bytes_t payload;
        if (z_bytes_from_str(&payload, buf, NULL, NULL) < 0) {
            printf("Error: Failed to create payload\n");
            continue;
        }
        
        if (z_publisher_put(z_loan(pub), z_move(payload), NULL) < 0) {
            printf("Error: Failed to publish message\n");
        }
        idx++;
    }

    printf("\nCleaning up...\n");
    z_drop(z_move(pub));
    z_drop(z_move(sub));
    zp_stop_read_task(z_loan_mut(s));
    zp_stop_lease_task(z_loan_mut(s));
    z_drop(z_move(s));

    return 0;
}
#else
int main(void) {
    printf("ERROR: Zenoh pico was compiled without Z_FEATURE_SUBSCRIPTION but this example requires it.\n");
    return -2;
}
#endif