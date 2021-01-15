class axi_slave extends uvm_agent;
    `uvm_component_utils(axi_slave)
    
    // Components
    axi_s_driver drv;
    axi_s_monitor mon;
    uvm_analysis_port#(axi_transaction#(D_WIDTH, A_WIDTH)) ap;

    // Variables
    env_config env_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    //  Function: build_phase
    extern function void build_phase(uvm_phase phase);
    
    //  Function: connect_phase
    extern function void connect_phase(uvm_phase phase);
    
endclass //axi_slave extends uvm_agent

function void axi_slave::build_phase(uvm_phase phase);
    env_cfg = new("env_cfg");
    assert (uvm_config_db#(env_config)::get(this, "", "config", env_cfg)) begin
        `uvm_info(get_name(), "vif has been found in ConfigDB.", UVM_LOW)
    end else `uvm_fatal(get_name(), "vif cannot be found in ConfigDB!")
    
    drv = axi_s_driver::type_id::create("drv", this);
    mon = axi_s_monitor::type_id::create("mon", this);
    
    drv.vif = env_cfg.intf;
    mon.vif = env_cfg.intf;

    ap = new("ap", this);
endfunction: build_phase

function void axi_slave::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);
endfunction: connect_phase

