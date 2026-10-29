`ifndef __GUARD_APB_UART_BASE_TESTS_SV__
`define __GUARD_APB_UART_BASE_TESTS_SV__ 0

// Shared test setup only; derived tests own all stimulus and transactions.
class apb_uart_base_test extends uvm_test;

    `uvm_component_utils(apb_uart_base_test)

    apb_uart_env env;

    function new(string name = "apb_uart_base_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = apb_uart_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);

        uvm_root::get().print_topology();
    endfunction

endclass : apb_uart_base_test

`endif
