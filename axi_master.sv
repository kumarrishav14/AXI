class axi_master extends uvm_agent;
    `uvm_component_utils(axi_master)
    
    // Components
    uvm_sequencer#(axi_transaction) w_seqr;
    uvm_sequencer#(axi_transaction) r_seqr;
    axi_m_driver drv;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    //  Function: build_phase
    extern function void build_phase(uvm_phase phase);
    
    //  Function: connect_phase
    extern function void connect_phase(uvm_phase phase);
    
endclass //axi_master extends uvm_agent

function void axi_master::build_phase(uvm_phase phase);
    /*  note: Do not call super.build_phase() from any class that is extended from an UVM base class!  */
    /*  For more information see UVM Cookbook v1800.2 p.503  */
    //super.build_phase(phase);

    drv = axi_m_driver::type_id::create("drv", this);
    w_seqr = uvm_sequencer#(axi_transaction)::type_id::create("w_seqr", this);
    r_seqr = uvm_sequencer#(axi_transaction)::type_id::create("r_seqr", this);
endfunction: build_phase

function void axi_master::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    drv.seq_item_port.connect(w_seqr.seq_item_export);
    drv.seq_item_port2.connect(r_seqr.seq_item_export);
endfunction: connect_phase

