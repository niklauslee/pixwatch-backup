/* Copyright (c) 2014 Nordic Semiconductor. All Rights Reserved.
 *
 * The information contained herein is property of Nordic Semiconductor ASA.
 * Terms and conditions of usage are described in detail in NORDIC
 * SEMICONDUCTOR STANDARD SOFTWARE LICENSE AGREEMENT.
 *
 * Licensees are granted free, non-transferable use of the information. NO
 * WARRANTY of ANY KIND is provided. This heading must NOT be removed from
 * the file.
 *
 */

/** @file
 *
 * @defgroup ble_sdk_app_cts_c_main main.c
 * @{
 * @ingroup ble_sdk_app_cts_c
 * @brief Current Time Profile sample application.
 *
 * This file contains the source code for a sample application that uses Current Time Service.
 * This is the client role of the profile, implemented on a peripheral device.
 * When a central device connects, the application will trigger a security procedure (if this is not done
 * by the central side first). Completion of the security procedure will trigger a service
 * discovery. When the Current Time Service and Characteristic have been discovered on the
 * server, pressing button 1 will trigger a read of the current time and print it on the UART.
 *
 */

#include <stdint.h>
#include <string.h>
#include <time.h>
#include "app_error.h"
#include "app_scheduler.h"
#include "app_timer_appsh.h"
#include "app_trace.h"
#include "ble.h"
#include "ble_db_discovery.h"
#include "ble_hci.h"
#include "ble_srv_common.h"
#include "ble_advdata.h"
#include "ble_advertising.h"
#include "ble_conn_params.h"
#include "device_manager.h"
#include "nordic_common.h"
#include "nrf.h"
#include "nrf_gpio.h"
#include "pstorage.h"
#include "softdevice_handler.h"
#include "app_uart.h"
#include "app_button.h"
#include "ble_pixwatch_c.h"
#include "display.h"

#define UART_TX_BUF_SIZE                1024         /**< UART TX buffer size. */
#define UART_RX_BUF_SIZE                1            /**< UART RX buffer size. */

#define IS_SRVC_CHANGED_CHARACT_PRESENT 0            /**< Include or exclude the service_changed characteristic. If excluded, the server's database cannot be changed for the lifetime of the device. */

#define WAKEUP_BUTTON_ID                0            /**< Button used to wake up the application. */
#define BOND_DELETE_ALL_BUTTON_ID       1            /**< Button used to delete all bonded centrals during startup. */
#define CURRENT_TIME_READ_BUTTON_ID     0            /**< Button used to read the current time from the server/central. */

#define DEVICE_NAME                     "PixWatch"   /**< Name of the device. Will be included in the advertising data. */
#define APP_ADV_FAST_INTERVAL           0x0028       /**< Fast advertising interval (in units of 0.625 ms). The default value corresponds to 25 ms. */
#define APP_ADV_SLOW_INTERVAL           0x0C80       /**< Slow advertising interval (in units of 0.625 ms). The default value corresponds to 2 seconds. */
#define APP_ADV_SLOW_TIMEOUT            180          /**< The duration of the slow advertising period (in seconds). */
#define APP_ADV_FAST_TIMEOUT            30           /**< The duration of the fast advertising period (in seconds). */

#define APP_TIMER_PRESCALER             0                                           /**< Value of the RTC1 PRESCALER register. */
#define APP_TIMER_MAX_TIMERS            (3 + 4)                                     /**< Maximum number of simultaneously created timers. */
#define APP_TIMER_OP_QUEUE_SIZE         4                                           /**< Size of timer operation queues. */

#define MIN_CONN_INTERVAL               MSEC_TO_UNITS(500, UNIT_1_25_MS)            /**< Minimum acceptable connection interval (0.5 seconds). */
#define MAX_CONN_INTERVAL               MSEC_TO_UNITS(1000, UNIT_1_25_MS)           /**< Maximum acceptable connection interval (1 second). */
#define SLAVE_LATENCY                   0                                           /**< Slave latency. */
#define CONN_SUP_TIMEOUT                MSEC_TO_UNITS(4000, UNIT_10_MS)             /**< Connection supervisory time-out (4 seconds). */
#define FIRST_CONN_PARAMS_UPDATE_DELAY  APP_TIMER_TICKS(5000, APP_TIMER_PRESCALER)  /**< Time from initiating event (connect or start of notification) to first time sd_ble_gap_conn_param_update is called (5 seconds). */
#define NEXT_CONN_PARAMS_UPDATE_DELAY   APP_TIMER_TICKS(30000, APP_TIMER_PRESCALER) /**< Time between each call to sd_ble_gap_conn_param_update after the first call (30 seconds). */
#define MAX_CONN_PARAMS_UPDATE_COUNT    3                                           /**< Number of attempts before giving up the connection parameter negotiation. */

#define SECURITY_REQUEST_DELAY          APP_TIMER_TICKS(4000, APP_TIMER_PRESCALER)  /**< Delay after connection until security request is sent, if necessary (ticks). */
#define REALTIME_CLOCK_INTERVAL         APP_TIMER_TICKS(1000, APP_TIMER_PRESCALER)  /**< Real-time clock (ticks for every seconds). */

#define SEC_PARAM_TIMEOUT               30                                          /**< Time-out for pairing request or security request (in seconds). */
#define SEC_PARAM_BOND                  1                                           /**< Perform bonding. */
#define SEC_PARAM_MITM                  0                                           /**< Man In The Middle protection requirement. */
#define SEC_PARAM_IO_CAPABILITIES       BLE_GAP_IO_CAPS_NONE                        /**< I/O capabilities. */
#define SEC_PARAM_OOB                   0                                           /**< Out Of Band data availability. */
#define SEC_PARAM_MIN_KEY_SIZE          7                                           /**< Minimum encryption key size. */
#define SEC_PARAM_MAX_KEY_SIZE          16                                          /**< Maximum encryption key size. */

#define DEAD_BEEF                       0xDEADBEEF                                  /**< Value used as error code on stack dump, can be used to identify stack location on stack unwind. */

#define BUTTON_1       13
#define BUTTON_2       14
#define BUTTON_3       15
#define BUTTON_4       16

#define LED_1          17
#define LED_2          18
#define LED_3          19
#define LED_4          20

#define RX_PIN_NUMBER  8
#define TX_PIN_NUMBER  6
#define CTS_PIN_NUMBER 7
#define RTS_PIN_NUMBER 5

#define BUTTON_DEBOUNCE_DELAY			50


static uint16_t m_conn_handle               = BLE_CONN_HANDLE_INVALID; /**< Handle of the current connection. */

static ble_db_discovery_t        m_ble_db_discovery;                   /**< Structure used to identify the DB Discovery module. */
static ble_pixwatch_c_t          m_pixwatch;                           /**< Structure to store the data of the pixwatch service. */
static dm_application_instance_t m_app_handle;                         /**< Application identifier allocated by the Device Manager. */
static dm_handle_t               m_peer_handle;                        /**< The peer that is currently connected. */

static app_timer_id_t m_sec_req_timer_id;                              /**< Security request timer. */
static app_timer_id_t m_realtime_timer_id;                             /**< Real-time timer */

#define SCHED_MAX_EVENT_DATA_SIZE sizeof(app_timer_event_t)            /**< Maximum size of scheduler events. Note that scheduler BLE stack events do not contain any data, as the events are being pulled from the stack in the event handler. */
#define SCHED_QUEUE_SIZE          10                                   /**< Maximum number of events in the scheduler queue. */

static ble_uuid_t m_adv_uuids[] = {{PIXWATCH_UUID_SERVICE, BLE_UUID_TYPE_VENDOR_BEGIN}}; /**< Universally unique service identifiers. */

/* Current Time */
time_t current_time = 0;


/**@brief Callback function for asserts in the SoftDevice.
 *
 * @details This function will be called in case of an assert in the SoftDevice.
 *
 * @warning This handler is an example only and does not fit a final product. You need to analyze
 *          how your product is supposed to react in case of Assert.
 * @warning On assert from the SoftDevice, the system can only recover on reset.
 *
 * @param[in] line_num  Line number of the failing ASSERT call.
 * @param[in] file_name File name of the failing ASSERT call.
 */
void assert_nrf_callback(uint16_t line_num, const uint8_t * p_file_name)
{
    app_error_handler(DEAD_BEEF, line_num, p_file_name);
}


/**@brief Function for handling the Current Time Service errors.
 *
 * @param[in]  nrf_error  Error code containing information about what went wrong.
 */
static void current_time_error_handler(uint32_t nrf_error)
{
    APP_ERROR_HANDLER(nrf_error);
}


/**@brief Function for handling UART errors.
 *
 * @param[in] nrf_error  Error code containing information about what went wrong.
 */
static void uart_error_handle(app_uart_evt_t * p_event)
{
    if (p_event->evt_type == APP_UART_COMMUNICATION_ERROR)
    {
        APP_ERROR_HANDLER(p_event->data.error_communication);
    }
    else if (p_event->evt_type == APP_UART_FIFO_ERROR)
    {
        APP_ERROR_HANDLER(p_event->data.error_code);
    }
}

static void on_pixwatch_c_evt(ble_pixwatch_c_t * p_pixwatch, ble_pixwatch_c_evt_t * p_evt)
{
    switch (p_evt->evt_type)
    {
        case BLE_PIXWATCH_C_EVT_DISCOVERY_COMPLETE:
            printf("Current Time Service discovered on server.\n");
            break;

        case BLE_PIXWATCH_C_EVT_SERVICE_NOT_FOUND:
            printf("Current Time Service not found on server.\n");
            break;

        case BLE_PIXWATCH_C_EVT_DISCONN_COMPLETE:
            printf("Disconnect Complete.\n");
            break;

        case BLE_PIXWATCH_C_EVT_LOCAL_TIME:
            printf("Current Time received.\n");
            current_time = p_evt->local_time;
            break;

        default:
            break;
    }
}


static void pixwatch_error_handler(uint32_t nrf_error)
{
    APP_ERROR_HANDLER(nrf_error);
}


/**@brief Function for handling the security request timer time-out.
 *
 * @details This function will be called each time the security request timer expires.
 *
 * @param[in] p_context  Pointer used for passing some arbitrary information (context) from the
 *                       app_start_timer() call to the time-out handler.
 */
static void sec_req_timeout_handler(void * p_context)
{
    uint32_t             err_code;
    dm_security_status_t status;

    if (m_conn_handle != BLE_CONN_HANDLE_INVALID)
    {
        err_code = dm_security_status_req(&m_peer_handle, &status);
        APP_ERROR_CHECK(err_code);

        // If the link is still not secured by the peer, initiate security procedure.
        if (status == NOT_ENCRYPTED)
        {
            err_code = dm_security_setup_req(&m_peer_handle);
            APP_ERROR_CHECK(err_code);
        }
    }
}


static void button_handler(uint8_t pin_no, uint8_t button_action)
{
    if(button_action == APP_BUTTON_PUSH)
    {
    	uint32_t err_code;

        switch(pin_no)
        {
            case BUTTON_1:
                nrf_gpio_pin_toggle(LED_1);
                if (m_conn_handle != BLE_CONN_HANDLE_INVALID)
                {
                    err_code = ble_pixwatch_c_local_time_read(&m_pixwatch);
                    if (err_code == NRF_ERROR_NOT_FOUND)
                    {
                    	printf("ERROR: %d\n", err_code);
                        printf("Current Time Service is not discovered.\r\n");
                    }
                }
                break;

            case BUTTON_2:
                nrf_gpio_pin_toggle(LED_2);
            	struct tm *t;
            	t = localtime(&current_time);
                printf("Local Time (Unix Time + Local Offset): %d\n", current_time);
                printf("Year: %d\n",   t->tm_year + 1900);
                printf("Month: %d\n",   t->tm_mon + 1);
                printf("Day: %d\n", t->tm_mday);
                printf("Hour: %d\n",   t->tm_hour);
                printf("Minute: %d\n",   t->tm_min);
                printf("Second: %d\n", t->tm_sec);
                printf("Day of Week: %d\n", t->tm_wday); // Sun=0, Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6
                break;

            case BUTTON_3:
            	printf("button_3 pressed.\n");
                nrf_gpio_pin_toggle(LED_3);
                break;

            case BUTTON_4:
            	printf("button_4 pressed.\n");
                nrf_gpio_pin_toggle(LED_4);

                break;
            default:
                break;
        }
    }
}


static void realtime_timer_handler(void * p_context)
{
	current_time++;

	struct tm *t;
	t = localtime(&current_time);

	putDigit(0, 0, t->tm_hour / 10, BLUE, BLACK);
	putDigit(4, 0, t->tm_hour % 10, BLUE, BLACK);

	putDigit(12, 0, t->tm_min / 10, BLUE, BLACK);
	putDigit(16, 0, t->tm_min % 10, BLUE, BLACK);

	putDigit(24, 0, t->tm_sec / 10, BLUE, BLACK);
	putDigit(28, 0, t->tm_sec % 10, BLUE, BLACK);
}


/**@brief Function for the timer initialization.
 *
 * @details Initializes the timer module.
 */
static void timers_init(void)
{
    uint32_t err_code;

    // Initialize timer module, making it use the scheduler
    APP_TIMER_APPSH_INIT(APP_TIMER_PRESCALER, APP_TIMER_MAX_TIMERS, APP_TIMER_OP_QUEUE_SIZE, true);

    // Create security request timer.
    err_code = app_timer_create(&m_sec_req_timer_id, APP_TIMER_MODE_SINGLE_SHOT, sec_req_timeout_handler);
    APP_ERROR_CHECK(err_code);

    // Create real-time timer.
    err_code = app_timer_create(&m_realtime_timer_id, APP_TIMER_MODE_REPEATED, realtime_timer_handler);
    APP_ERROR_CHECK(err_code);
}


/**@brief Function for the GAP initialization.
 *
 * @details This function sets up all the necessary GAP (Generic Access Profile) parameters of the
 *          device including the device name, appearance, and the preferred connection parameters.
 */
static void gap_params_init(void)
{
    uint32_t                err_code;
    ble_gap_conn_params_t   gap_conn_params;
    ble_gap_conn_sec_mode_t sec_mode;

    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&sec_mode);

    err_code = sd_ble_gap_device_name_set(&sec_mode,
                                          (const uint8_t *)DEVICE_NAME,
                                          strlen(DEVICE_NAME));
    APP_ERROR_CHECK(err_code);

    memset(&gap_conn_params, 0, sizeof(gap_conn_params));

    gap_conn_params.min_conn_interval = MIN_CONN_INTERVAL;
    gap_conn_params.max_conn_interval = MAX_CONN_INTERVAL;
    gap_conn_params.slave_latency     = SLAVE_LATENCY;
    gap_conn_params.conn_sup_timeout  = CONN_SUP_TIMEOUT;

    err_code = sd_ble_gap_ppcp_set(&gap_conn_params);
    APP_ERROR_CHECK(err_code);
}



/**@brief Function for initializing services that will be used by the application.
 */
static void services_init(void)
{
    uint32_t         err_code;
    ble_pixwatch_c_init_t pixwatch_init_obj;

    uint8_t m_pixwatch_uuid_type;
    ble_uuid_t service_uuid;

    err_code = sd_ble_uuid_vs_add(&ble_pixwatch_base_uuid128, &m_pixwatch_uuid_type);
    APP_ERROR_CHECK(err_code);

    err_code = sd_ble_uuid_vs_add(&ble_pixwatch_local_time_base_uuid128, &service_uuid.type);
    APP_ERROR_CHECK(err_code);

    pixwatch_init_obj.evt_handler   = on_pixwatch_c_evt;
    pixwatch_init_obj.error_handler = pixwatch_error_handler;

    err_code = ble_pixwatch_c_init(&m_pixwatch, &pixwatch_init_obj);
    APP_ERROR_CHECK(err_code);
}


/**@brief Function for handling the Connection Parameters module.
 *
 * @details This function will be called for all events in the Connection Parameters module that
 *          are passed to the application.
 *          @note All this function does is to disconnect. This could have been done by simply
 *                setting the disconnect_on_fail config parameter, but instead we use the event
 *                handler mechanism to demonstrate its use.
 *
 * @param[in] p_evt  Event received from the Connection Parameters module.
 */
static void on_conn_params_evt(ble_conn_params_evt_t * p_evt)
{
    uint32_t err_code;

    if (p_evt->evt_type == BLE_CONN_PARAMS_EVT_FAILED)
    {
        err_code = sd_ble_gap_disconnect(m_conn_handle, BLE_HCI_CONN_INTERVAL_UNACCEPTABLE);
        APP_ERROR_CHECK(err_code);
    }
}


/**@brief Function for handling a Connection Parameters error.
 *
 * @param[in]   nrf_error   Error code containing information about what went wrong.
 */
static void conn_params_error_handler(uint32_t nrf_error)
{
    APP_ERROR_HANDLER(nrf_error);
}


/**@brief Function for initializing the Connection Parameters module.
 */
static void conn_params_init(void)
{
    uint32_t               err_code;
    ble_conn_params_init_t cp_init;

    memset(&cp_init, 0, sizeof(cp_init));

    cp_init.p_conn_params                  = NULL;
    cp_init.first_conn_params_update_delay = FIRST_CONN_PARAMS_UPDATE_DELAY;
    cp_init.next_conn_params_update_delay  = NEXT_CONN_PARAMS_UPDATE_DELAY;
    cp_init.max_conn_params_update_count   = MAX_CONN_PARAMS_UPDATE_COUNT;
    cp_init.start_on_notify_cccd_handle    = BLE_GATT_HANDLE_INVALID;
    cp_init.disconnect_on_fail             = false;
    cp_init.evt_handler                    = on_conn_params_evt;
    cp_init.error_handler                  = conn_params_error_handler;

    err_code = ble_conn_params_init(&cp_init);
    APP_ERROR_CHECK(err_code);
}


/**@brief Function for dispatching a system event to interested modules.
 *
 * @details This function is called from the system event interrupt handler after a system
 *          event has been received.
 *
 * @param[in] sys_evt  System stack event.
 */
static void sys_evt_dispatch(uint32_t sys_evt)
{
    pstorage_sys_event_handler(sys_evt);
    ble_advertising_on_sys_evt(sys_evt);
}


/**@brief Function for handling the Device Manager events.
 *
 * @param[in] p_evt  Data associated to the Device Manager event.
 */
static uint32_t device_manager_evt_handler(dm_handle_t const * p_handle,
                                           dm_event_t const  * p_event,
                                           ret_code_t        event_result)
{
    uint32_t err_code;

    APP_ERROR_CHECK(event_result);

    switch (p_event->event_id)
    {
        case DM_EVT_CONNECTION:
            m_peer_handle = (*p_handle);
            err_code      = app_timer_start(m_sec_req_timer_id, SECURITY_REQUEST_DELAY, NULL);
            APP_ERROR_CHECK(err_code);

            err_code      = app_timer_start(m_realtime_timer_id, REALTIME_CLOCK_INTERVAL, NULL);
            APP_ERROR_CHECK(err_code);
            break;

        case DM_EVT_LINK_SECURED:
            err_code = ble_db_discovery_start(&m_ble_db_discovery,
                                              p_event->event_param.p_gap_param->conn_handle);
            APP_ERROR_CHECK(err_code);
            break;

        default:
            // No implementation needed.
            break;

    }
    return NRF_SUCCESS;
}


/**@brief Function for the Device Manager initialization.
 *
 * @param[in] erase_bonds  Indicates whether bonding information should be cleared from
 *                         persistent storage during initialization of the Device Manager.
 */
static void device_manager_init(bool erase_bonds)
{
    uint32_t               err_code;
    dm_init_param_t        init_param = {.clear_persistent_data = erase_bonds};
    dm_application_param_t register_param;

    // Initialize persistent storage module.
    err_code = pstorage_init();
    APP_ERROR_CHECK(err_code);

    err_code = dm_init(&init_param);
    APP_ERROR_CHECK(err_code);

    memset(&register_param.sec_param, 0, sizeof(ble_gap_sec_params_t));

    register_param.sec_param.bond         = SEC_PARAM_BOND;
    register_param.sec_param.mitm         = SEC_PARAM_MITM;
    register_param.sec_param.io_caps      = SEC_PARAM_IO_CAPABILITIES;
    register_param.sec_param.oob          = SEC_PARAM_OOB;
    register_param.sec_param.min_key_size = SEC_PARAM_MIN_KEY_SIZE;
    register_param.sec_param.max_key_size = SEC_PARAM_MAX_KEY_SIZE;
    register_param.evt_handler            = device_manager_evt_handler;
    register_param.service_type           = DM_PROTOCOL_CNTXT_GATT_CLI_ID;

    err_code = dm_register(&m_app_handle, &register_param);
    APP_ERROR_CHECK(err_code);
}


/**@brief Function for putting the chip into sleep mode.
 *
 * @note This function will not return.
 */
static void sleep_mode_enter(void)
{
    // uint32_t err_code = bsp_indication_set(BSP_INDICATE_IDLE);
    // APP_ERROR_CHECK(err_code);

    // Prepare wakeup buttons.
    // err_code = bsp_btn_ble_sleep_mode_prepare();
    // APP_ERROR_CHECK(err_code);

    // Go to system-off mode (this function will not return; wakeup will cause a reset).
	uint32_t err_code = sd_power_system_off();
    APP_ERROR_CHECK(err_code);
}


/**@brief Function for handling advertising events.
 *
 * @details This function will be called for advertising events which are passed to the application.
 *
 * @param[in] ble_adv_evt  Advertising event.
 */
static void on_adv_evt(ble_adv_evt_t ble_adv_evt)
{
    uint32_t err_code;

    switch (ble_adv_evt)
    {
        case BLE_ADV_EVT_DIRECTED:
            // err_code = bsp_indication_set(BSP_INDICATE_ADVERTISING_DIRECTED);
            // APP_ERROR_CHECK(err_code);
            break;
        case BLE_ADV_EVT_FAST:
            // err_code = bsp_indication_set(BSP_INDICATE_ADVERTISING);
            // APP_ERROR_CHECK(err_code);
            break;
        case BLE_ADV_EVT_SLOW:
            // err_code = bsp_indication_set(BSP_INDICATE_ADVERTISING_SLOW);
            // APP_ERROR_CHECK(err_code);
            break;
        case BLE_ADV_EVT_FAST_WHITELIST:
            // err_code = bsp_indication_set(BSP_INDICATE_ADVERTISING_WHITELIST);
            // APP_ERROR_CHECK(err_code);
            break;
        case BLE_ADV_EVT_SLOW_WHITELIST:
            // err_code = bsp_indication_set(BSP_INDICATE_ADVERTISING_WHITELIST);
            // APP_ERROR_CHECK(err_code);
            err_code = ble_advertising_restart_without_whitelist();
            APP_ERROR_CHECK(err_code);
            break;
        case BLE_ADV_EVT_IDLE:
            // sleep_mode_enter();
            break;

        case BLE_ADV_EVT_WHITELIST_REQUEST:
        {
            ble_gap_whitelist_t whitelist;
            ble_gap_addr_t    * p_whitelist_addr[BLE_GAP_WHITELIST_ADDR_MAX_COUNT];
            ble_gap_irk_t     * p_whitelist_irk[BLE_GAP_WHITELIST_IRK_MAX_COUNT];

            whitelist.addr_count = BLE_GAP_WHITELIST_ADDR_MAX_COUNT;
            whitelist.irk_count  = BLE_GAP_WHITELIST_IRK_MAX_COUNT;
            whitelist.pp_addrs   = p_whitelist_addr;
            whitelist.pp_irks    = p_whitelist_irk;

            err_code = dm_whitelist_create(&m_app_handle, &whitelist);
            APP_ERROR_CHECK(err_code);

            err_code = ble_advertising_whitelist_reply(&whitelist);
            APP_ERROR_CHECK(err_code);
            break;
        }
        default:
            break;
    }
}


/**@brief Function for dispatching a BLE stack event to all modules with a BLE stack event handler.
 *
 * @details This function is called from the scheduler in the main loop after a BLE stack
 *          event has been received.
 *
 * @param[in] p_ble_evt  Bluetooth stack event.
 */
static void ble_evt_dispatch(ble_evt_t * p_ble_evt)
{
	uint32_t err_code;

    dm_ble_evt_handler(p_ble_evt);
    ble_db_discovery_on_ble_evt(&m_ble_db_discovery, p_ble_evt);

    switch (p_ble_evt->header.evt_id)
    {
        case BLE_GAP_EVT_CONNECTED:
            m_conn_handle      = p_ble_evt->evt.gap_evt.conn_handle;
            break;

        case BLE_GAP_EVT_DISCONNECTED:
            m_conn_handle = BLE_CONN_HANDLE_INVALID;
            break;

        default:
            // No implementation needed.
            break;
    }

    ble_conn_params_on_ble_evt(p_ble_evt);
    ble_pixwatch_c_on_ble_evt(&m_pixwatch, p_ble_evt);
    ble_advertising_on_ble_evt(p_ble_evt);
}


/**@brief Function for initializing the BLE stack.
 *
 * @details Initializes the SoftDevice and the BLE event interrupt.
 */
static void ble_stack_init(void)
{
    uint32_t err_code;

    // Initialize the SoftDevice handler module.
    SOFTDEVICE_HANDLER_INIT(NRF_CLOCK_LFCLKSRC_XTAL_20_PPM, NULL);

#if defined(S110) || defined(S130) || defined(S132)
    // Enable BLE stack
    ble_enable_params_t ble_enable_params;
    memset(&ble_enable_params, 0, sizeof(ble_enable_params));
#if (defined(S130) || defined(S132))
    ble_enable_params.gatts_enable_params.attr_tab_size   = BLE_GATTS_ATTR_TAB_SIZE_DEFAULT;
#endif
    ble_enable_params.gatts_enable_params.service_changed = IS_SRVC_CHANGED_CHARACT_PRESENT;
    err_code = sd_ble_enable(&ble_enable_params);
    APP_ERROR_CHECK(err_code);
#endif

    // Register with the SoftDevice handler module for BLE events.
    err_code = softdevice_ble_evt_handler_set(ble_evt_dispatch);
    APP_ERROR_CHECK(err_code);

    // Register with the SoftDevice handler module for BLE events.
    err_code = softdevice_sys_evt_handler_set(sys_evt_dispatch);
    APP_ERROR_CHECK(err_code);
}


/**@brief Function for the Event Scheduler initialization.
 */
static void scheduler_init(void)
{
    APP_SCHED_INIT(SCHED_MAX_EVENT_DATA_SIZE, SCHED_QUEUE_SIZE);
}


/**@brief Function for initializing the advertising functionality.
 *
 * @details Encodes the required advertising data and passes it to the stack.
 *          Also builds a structure to be passed to the stack when starting advertising.
 */
static void advertising_init()
{
    uint32_t      err_code;
    ble_advdata_t advdata;
    ble_advdata_t scanrsp;

    // Build and set advertising data
    memset(&advdata, 0, sizeof(advdata));

    advdata.name_type                = BLE_ADVDATA_FULL_NAME;
    advdata.include_appearance       = true;
    advdata.flags                    = BLE_GAP_ADV_FLAGS_LE_ONLY_LIMITED_DISC_MODE;

    memset(&scanrsp, 0, sizeof(scanrsp));
    scanrsp.uuids_solicited.uuid_cnt = sizeof(m_adv_uuids) / sizeof(m_adv_uuids[0]);
    scanrsp.uuids_solicited.p_uuids  = m_adv_uuids;

    ble_adv_modes_config_t options    = {0};
    options.ble_adv_whitelist_enabled = BLE_ADV_WHITELIST_ENABLED;
    options.ble_adv_fast_enabled      = BLE_ADV_FAST_ENABLED;
    options.ble_adv_fast_interval     = APP_ADV_FAST_INTERVAL;
    options.ble_adv_fast_timeout      = APP_ADV_FAST_TIMEOUT;
    options.ble_adv_slow_enabled      = BLE_ADV_SLOW_ENABLED;
    options.ble_adv_slow_interval     = APP_ADV_SLOW_INTERVAL;
    options.ble_adv_slow_timeout      = APP_ADV_SLOW_TIMEOUT;

    err_code = ble_advertising_init(&advdata, &scanrsp, &options, on_adv_evt, NULL);
    APP_ERROR_CHECK(err_code);
}


static void buttons_leds_init(void) {
	uint32_t err_code;

    nrf_gpio_cfg_output(LED_1);
    nrf_gpio_cfg_output(LED_2);
    nrf_gpio_cfg_output(LED_3);
    nrf_gpio_cfg_output(LED_4);
    nrf_gpio_pin_set(LED_1);
    nrf_gpio_pin_set(LED_2);
    nrf_gpio_pin_set(LED_3);
    nrf_gpio_pin_set(LED_4);

	static app_button_cfg_t p_button[] = {
			{BUTTON_1, false, NRF_GPIO_PIN_PULLUP, button_handler},
	        {BUTTON_2, false, NRF_GPIO_PIN_PULLUP, button_handler},
	        {BUTTON_3, false, NRF_GPIO_PIN_PULLUP, button_handler},
	        {BUTTON_4, false, NRF_GPIO_PIN_PULLUP, button_handler}
	};

    err_code = app_button_init(p_button, sizeof(p_button) / sizeof(p_button[0]), BUTTON_DEBOUNCE_DELAY);
    APP_ERROR_CHECK(err_code);

    err_code = app_button_enable();
    APP_ERROR_CHECK(err_code);
}

/**@brief Function for initializing the UART.
 */
static void uart_init(void)
{
    uint32_t                     err_code;
    const app_uart_comm_params_t comm_params =
    {
        RX_PIN_NUMBER,
        TX_PIN_NUMBER,
        RTS_PIN_NUMBER,
        CTS_PIN_NUMBER,
        APP_UART_FLOW_CONTROL_ENABLED,
        false,
        UART_BAUDRATE_BAUDRATE_Baud38400
    };

    APP_UART_FIFO_INIT(&comm_params,
                       UART_RX_BUF_SIZE,
                       UART_TX_BUF_SIZE,
                       uart_error_handle,
                       APP_IRQ_PRIORITY_LOW,
                       err_code);
    APP_ERROR_CHECK(err_code);
}


/**
 * @brief Database discovery collector initialization.
 */
static void db_discovery_init(void)
{
    uint32_t err_code = ble_db_discovery_init();

    APP_ERROR_CHECK(err_code);
}


/**@brief Function for the power manager.
 */
static void power_manage(void)
{
    uint32_t err_code = sd_app_evt_wait();

    APP_ERROR_CHECK(err_code);
}


/**@brief Function for application main entry.
 */
int main(void)
{
    uint32_t err_code;
    bool     erase_bonds;

    // Initialize
    app_trace_init();
    timers_init();
    buttons_leds_init();
    uart_init();
    printf("PixWatch Start!\n");
    ble_stack_init();
    device_manager_init(erase_bonds);
    db_discovery_init();
    scheduler_init();
    gap_params_init();
    services_init();
    advertising_init();
    conn_params_init();

    // Start execution
    err_code = ble_advertising_start(BLE_ADV_MODE_FAST);
    APP_ERROR_CHECK(err_code);
    printf("Advertising Started!\n");

    // Init display
    spi_master_init();
    initDisplay();
    drawRectangle(0, 0, 127, 95, BLACK);

    // Enter main loop
    for (;;)
    {
        app_sched_execute();
        power_manage();
    }
}


/**
 * @}
 */
