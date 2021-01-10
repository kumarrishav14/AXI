class axi_m_driver extends uvm_driver#(axi_transaction);
    `uvm_component_utils(axi_m_driver)
    
    // Components
    virtual axi_intf#(.DWIDTH(D_WIDTH), .AWIDTH(A_WIDTH)).MDRV vif;
    uvm_seq_item_pull_port#(REQ, RSP) seq_item_port2;

    // Variables
    REQ w_trans, r_trans;
    bit w_done, r_done;

    // Methods
    extern task drive();
    extern task send_write_address();
    extern task send_read_address();
    extern task send_write_data();
    extern task send_read_data();

    function new(string name, uvm_component parent);
        super.new(name, parent);
        w_done = 1;
        r_done = 1;
    endfunction //new()

    //  Function: build_phase
    extern function void build_phase(uvm_phase phase);
    
    //  Function: run_phase
    extern task run_phase(uvm_phase phase);
    
endclass //m_driver extends uvn_driver#(axu)

task axi_m_driver::run_phase(uvm_phase phase);
    forever begin
        drive();
    end
endtask: run_phase

task axi_m_driver::drive();
    if(!vif.rstn) begin
        vif.m_drv_cb.AWVALID <= 0;
        vif.m_drv_cb.WVALID <= 0;
        vif.m_drv_cb.ARVALID <= 0;
        return;
    end
    fork
        begin
            if(w_done) begin
                w_done = 0;
                seq_item_port.get_next_item(w_trans);
                send_write_address();
                seq_item_port.item_done();
                w_done = 1;
            end
            
        end
        begin
            if(r_done) begin
                r_done = 0;
                seq_item_prod2.get_next_item(r_trans);
                send_read_address();
                seq_item_port2.item_done();
                r_done = 1;
            end
        end
    join_none
endtask: drive

task axi_m_driver::send_write_address();
    vif.m_drv_cb.AWID   <= w_trans.id;
    vif.m_drv_cb.AWADDR <= w_trans.addr;
    vif.m_drv_cb.AWLEN  <= w_trans.b_len;
    vif.m_drv_cb.AWSIZE <= w_trans.b_size;
    vif.m_drv_cb.AWBURST<= w_trans.b_type;
    @(vif.m_drv_cb);
    vif.m_drv_cb.AWVALID<= 1;
endtask: send_write_address


