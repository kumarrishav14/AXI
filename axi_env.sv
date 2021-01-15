class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)

    // Components
    axi_master master;
    axi_slave slave;
    axi_scoreboard scb;

    env_config env_cfg;

    // 
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    //  Function: build_phase
    extern function void build_phase(uvm_phase phase);
    
    //  Function: connect_phase
    extern function void connect_phase(uvm_phase phase);
    
endclass //axi_env extends uvm_env

function void axi_env::build_phase(uvm_phase phase);
    /*  note: Do not call super.build_phase() from any class that is extended from an UVM base class!  */
    /*  For more information see UVM Cookbook v1800.2 p.503  */
    //super.build_phase(phase);

    master = axi_master::type_id::create("master", this);
    slave = axi_slave::type_id::create("slave", this);
    scb   = axi_scoreboard::type_id::create("scb", this);
endfunction: build_phase

function void axi_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    master.ap.connect(scb.m_ap_imp);
    slave.ap.connect(scb.s_ap_imp);
endfunction: connect_phase

