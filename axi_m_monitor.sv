class axi_m_monitor extends uvm_monitor;
    `uvm_component_utils(axi_m_monitor)

    // Components
    uvm_analysis_port#(axi_transaction#(.D_WIDTH(D_WIDTH), .A_WIDTH(AWIDTH))) ap;
    virtual axi_intf#(.D_WIDTH(D_WIDTH), .A_WIDTH(AWIDTH)).MMON vif;
    // variables
    axi_transaction#(.D_WIDTH(D_WIDTH), .A_WIDTH(AWIDTH)) w_trans, r_trans;
    bit w_done, r_done;
    int b_size;
    
    // Methods
    extern task run(uvm_phase phase);
    extern task write_monitor();
    extern task read_monitor();

    function new(string name, uvm_component parent);
        super.new(name, parent);
        w_done = 1;
        r_done = 1;
    endfunction //new()

    //  Function: build_phase
    extern function void build_phase(uvm_phase phase);
    
    //  Function: run_phase
    extern task run_phase(uvm_phase phase);
    
endclass //axi_m_monitor extends uvm_monitor

function void axi_m_monitor::build_phase(uvm_phase phase);
    /*  note: Do not call super.build_phase() from any class that is extended from an UVM base class!  */
    /*  For more information see UVM Cookbook v1800.2 p.503  */
    //super.build_phase(phase);

    ap = new("ap", this);
endfunction: build_phase

task axi_m_monitor::run_phase(uvm_phase phase);
    forever begin
        run(phase);
        @(vif.mon_cb);
    end
endtask: run_phase

task axi_m_monitor::run(uvm_phase phase);
    fork
        if(w_done) begin
            phase.raise_objection(this);
            w_done = 0;
            write_monitor();
            w_done = 1;
            phase.drop_objection(this);
        end
        // if(r_done) begin
        //     phase.raise_objection(this);
        //     r_done = 0;
        //     read_monitor();
        //     r_done = 1;
        //     phase.drop_objection(this);
        // end
        
    join_none
endtask: run

task axi_m_monitor::write_monitor();
    if(vif.mon_cb.AWVALID && vif.mon_cb.AWREADY) begin
        w_trans = axi_transaction#(.D_WIDTH(D_WIDTH), .A_WIDTH(AWIDTH))::type_id::create("w_trans");
        w_trans.addr    = vif.mon_cb.AWADDR;
        w_trans.id      = vif.mon_cb.AWID;
        w_trans.b_size  = vif.mon_cb.AWSIZE;
        w_trans.b_len   = vif.mon_cb.AWLEN;
        w_trans.b_type  = vif.mon_cb.AWBURST;
        ap.write(w_trans);
        w_trans.print();
    end

    if(vif.mon_cb.WVALID && vif.mon_cb.WREADY) begin
        w_trans = axi_transaction#(.D_WIDTH(D_WIDTH), .A_WIDTH(AWIDTH))::type_id::create("w_trans");
        w_trans.data    = new [1];
        w_trans.data[1] = new [D_WIDTH/8];
        for (int i=0; i<D_WIDTH/8; i++) begin
            w_trans.data[0][i] = vif.mon_cb.WDATA[8*i+:8];
        end
        w_trans.id      = vif.mon_cb.WID;
        w_trans.wlast   = vif.mon_cb.WLAST;
        ap.write(w_trans);
        w_trans.print();
    end
endtask: write_monitor



