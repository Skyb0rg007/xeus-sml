
// C++ standard library
#include <memory>
#include <iostream>
// C standard library
#include <cstdlib>
// nlohmann_json
#include <nlohmann/json.hpp>
// xeus
#include <xeus/xinterpreter.hpp>
#include <xeus/xinput.hpp>
#include <xeus/xkernel.hpp>
#include <xeus/xkernel_configuration.hpp>
// xeus-sml
#define PART_OF_XEUS_SML
extern "C" {
#include <xeus-sml-export.h>
}
// MLton internals
typedef Word64_t C_String_t; // TODO: determine if platform-specific
static_assert(sizeof(void *) == sizeof(C_String_t));

namespace nl = nlohmann;

namespace xeus_sml {

    class interpreter : public xeus::xinterpreter {
    public:
        interpreter() = default;
        virtual ~interpreter() = default;
    private:
        void configure_impl() override
        {
            xeus_sml_configure();
        }

        void shutdown_request_impl() override
        {
            xeus_sml_shutdown();
        }

        nl::json execute_request_impl(
                int execution_counter,
                const std::string &code,
                bool silent,
                bool store_history,
                nl::json user_expressions,
                bool allow_stdin) override
        {

            NullString8_t ret = xeus_sml_execute(
                    execution_counter,
                    reinterpret_cast<C_String_t>(code.c_str()),
                    silent,
                    store_history,
                    reinterpret_cast<C_String_t>(user_expressions.dump().c_str()),
                    allow_stdin);
            nl::json response = nl::json::parse(reinterpret_cast<const char *>(ret));

            if (response["status"] == std::string("ok")) {
                // Success - publish the 'publish' field, removing it from 'response'
                publish_execution_result(execution_counter, std::move(response["publish"]), /* metadata */ nl::json::object());
            } else if (response["status"] == std::string("error")) {
                // Show the error
                publish_execution_error(
                        std::move(response["ename"]),
                        std::move(response["evalue"]),
                        std::move(response["traceback"]));
            } else {
                return R"({ "status": "error", "ename": "xeus-sml", "evalue": "bug in library" })"_json;
            }

            return R"({ "status": "ok" })"_json;
        }

        nl::json complete_request_impl(
                const std::string &code,
                int cursor_pos) override
        {
            // TODO
            return R"({ "status": "ok" })"_json;
        }

        nl::json inspect_request_impl(
                const std::string &code,
                int cursor_pos,
                int detail_level) override
        {
            // TODO
            return R"({ "status": "ok" })"_json;
        }

        nl::json is_complete_request_impl(
                const std::string &code) override
        {
            // TODO
            return R"({ "status": "complete" })"_json;
        }

        nl::json kernel_info_request_impl() override
        {
            return nl::json::parse(reinterpret_cast<const char *>(xeus_sml_kernel_info()));
        }
    };

}

extern "C"
C_String_t xeus_sml_blocking_input(NullString8_t _prompt)
{
    auto prompt = std::string(reinterpret_cast<const char *>(_prompt));
    auto result = xeus::blocking_input_request(prompt, true);
    return reinterpret_cast<C_String_t>(strdup(result.c_str()));
}

extern "C"
void xeus_sml_blocking_input_free(C_String_t str)
{
    free(reinterpret_cast<void *>(str));
}

extern "C"
void xeus_sml_run(NullString8_t _filename)
{
#ifndef NDEBUG
    setenv("XEUS_LOG", "", /* overwrite */ false); // Debug build == always log
#endif
    try {
        auto filename = std::string(reinterpret_cast<const char *>(_filename));
        auto config = xeus::load_configuration(filename);
        auto interp = std::make_unique<xeus_sml::interpreter>();
        auto logger = xeus::make_console_logger(xeus::xlogger::msg_type);

        auto kernel = xeus::xkernel(
                config,
                xeus::get_user_name(),
                std::move(interp),
                xeus::make_in_memory_history_manager(),
                std::move(logger));
        kernel.start();
    } catch (const std::exception &e) {
        std::cerr << "C++ exception thrown: " << e.what() << std::endl;
    }
}

