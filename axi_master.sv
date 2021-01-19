class axi_master extends uvm_agent;
    `uvm_component_utils(axi_master)
    
    // Components
    uvm_sequencer#(axi_transaction#(D_WIDTH, A_WIDTH)) w_seqr;
    uvm_sequencer#(axi_transaction#(D_WIDTH, A_WIDTH)) r_seqr;
    axi_m_driver drv;
    axi_m_monitor mon;
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
    
endclass //axi_master extends uvm_agent

function void axi_master::build_phase(uvm_phase phase);
    env_cfg = new("env_cfg");
    assert (uvm_config_db#(env_config)::get(this, "", "config", env_cfg)) begin
        `uvm_info(get_name(), "vif has been found in ConfigDB.", UVM_LOW)
    end else `uvm_fatal(get_name(), "vif cannot be found in ConfigDB!")
    
    drv = axi_m_driver::type_id::create("drv", this);
    mon = axi_m_monitor::type_id::create("mon", this);
    w_seqr = uvm_sequencer#(axi_transaction#(D_WIDTH, A_WIDTH))::type_id::create("w_seqr", this);
    r_seqr = uvm_sequencer#(axi_transaction#(D_WIDTH, A_WIDTH))::type_id::create("r_seqr", this);
    
    drv.vif = env_cfg.intf;
    mon.vif = env_cfg.intf;

    ap = new("ap", this);
endfunction: build_phase

function void axi_master::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    drv.seq_item_port.connect(w_seqr.seq_item_export);
    drv.seq_item_port2.connect(r_seqr.seq_item_export);
    mon.ap.connect(ap);
endfunction: connect_phase

