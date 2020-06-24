
#include <memory>
#include <nlohmann/json.hpp>
#include <xeus/xinterpreter.hpp>
#define PART_OF_XEUS_SML
#include <xeus-sml-export.h>

extern "C"
PUBLIC int foo(void) {
    return 12;
}
