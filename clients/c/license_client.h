/**
 * @file license_client.h
 * @brief License Server Client Library for C
 * 
 * Simple HTTP client for borrowing and returning licenses from the
 * Mercedes-Benz license server.
 */

#ifndef LICENSE_CLIENT_H
#define LICENSE_CLIENT_H

#include <stddef.h>

/**
 * @brief License handle returned when borrowing a license
 */
typedef struct {
    char id[64];        /**< License UUID */
    char tool[64];      /**< Tool name */
    char user[64];      /**< Username */
    int valid;          /**< 1 if valid, 0 otherwise */
} license_handle_t;

/**
 * @brief License status information
 */
typedef struct {
    char tool[64];      /**< Tool name */
    int total;          /**< Total licenses */
    int borrowed;       /**< Currently borrowed */
    int available;      /**< Available to borrow */
} license_status_t;

/**
 * @brief Initialize the license client
 * 
 * @param base_url Base URL of the license server (e.g., "http://localhost:8000")
 * @return 0 on success, -1 on error
 */
int license_client_init(const char *base_url);

/**
 * @brief Cleanup the license client
 */
void license_client_cleanup(void);

/**
 * @brief Borrow a license for a specific tool
 * 
 * @param tool Tool name (e.g., "cad_tool")
 * @param user Username
 * @param handle Output parameter for license handle
 * @return 0 on success, -1 on error, -2 if no licenses available
 */
int license_borrow(const char *tool, const char *user, license_handle_t *handle);

/**
 * @brief Return a borrowed license
 * 
 * @param handle License handle to return
 * @return 0 on success, -1 on error
 */
int license_return(const license_handle_t *handle);

/**
 * @brief Get status for a specific tool
 * 
 * @param tool Tool name
 * @param status Output parameter for status
 * @return 0 on success, -1 on error
 */
int license_get_status(const char *tool, license_status_t *status);

/**
 * @brief Get the last error message
 * 
 * @return Error message string
 */
const char* license_get_error(void);

#endif /* LICENSE_CLIENT_H */

