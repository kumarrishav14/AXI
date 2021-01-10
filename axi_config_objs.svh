import uvm_pkg::*;

class env_config extends uvm_object;
    `uvm_object_utils(env_config)
    
    // variables
    virtual axi_intf#(.D_WIDTH(D_WIDTH), .A_WIDTH(A_WIDTH)) intf;

    // Master and Slave are active or passive
    uvm_active_passive_enum active = UVM_ACTIVE;
    
    // no_of_test_cases
    int no_of_w_cases;
    int no_of_r_cases;

    function new(string name = "env_config");
        super.new(name);
    endfunction //new()
endclass //env_config extends uvm_object