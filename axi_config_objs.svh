import uvm_pkg::*;

class env_config extends uvm_object;
    `uvm_object_utils(env_config)
    
    // variables
    virtual axi_intf;

    // Master and Slave are active or passive
    uvm_active_passive_enum active = UVM_ACTIVE;

    // Width of Address and Data Bus
    parameter A_WIDTH = 16;
    parameter D_WIDTH = 16;
    
    // no_of_test_cases
    int no_of_w_cases;
    int no_of_r_cases;
    
    function new(string name = "env_config");
        super.new(name);
    endfunction //new()
endclass //env_config extends uvm_object