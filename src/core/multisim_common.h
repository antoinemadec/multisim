#pragma once

#include <stdint.h>
#if !defined(MULTISIM_SW)
#include <svdpi.h>
#endif

#if defined(MULTISIM_EMULATION) || defined(MULTISIM_SW)
typedef uint32_t *data_handle_t;
#else
typedef svOpenArrayHandle data_handle_t;
#endif

#define MULTISIM_SERVER_MAX 1024

#define MULTISIM_SUCCESS 1
#define MULTISIM_FAIL 0

