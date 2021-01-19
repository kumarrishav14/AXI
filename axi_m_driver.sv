class axi_m_driver extends uvm_driver#(axi_transaction#(D_WIDTH, A_WIDTH));
    `uvm_component_utils(axi_m_driver)
    
    // Components
    virtual axi_intf#(.D_WIDTH(D_WIDTH), .A_WIDTH(A_WIDTH)).MDRV vif;
    uvm_seq_item_pull_port#(REQ, RSP) seq_item_port2;

    // Variables
    REQ w_trans, r_trans;
    bit w_done, r_done;
    bit [D_WIDTH-1:0] temp [];
    logic AWVALID;

    // Methods
    extern task drive();
    extern task send_write_address();
    extern task send_read_address();
    extern task send_write_data();
    // extern task send_read_data();

    function new(string name, uvm_component parent);
        super.new(name, parent);
        w_done = 1;
        r_done = 1;
        seq_item_port2 = new("seq_item_port2", this);
    endfunction //new()

    //  Function: build_phase
    // extern function void build_phase(uvm_phase phase);
    
    //  Function: run_phase
    extern task run_phase(uvm_phase phase);
    
endclass //m_driver extends uvn_driver#(axu)

task axi_m_driver::run_phase(uvm_phase phase);
    `uvm_info("DEBUG", "started master driver", UVM_HIGH)
    // temp 
    vif.m_drv_cb.BREADY <= 1;
    vif.m_drv_cb.RREADY <= 1;
    forever begin
        drive();
        #1;
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
            `uvm_info("DEBUG", $sformatf("w_addr(), w_done = %0d", w_done), UVM_DEBUG)
            if(w_done) begin
                w_done = 0;
                seq_item_port.get_next_item(w_trans);
                `uvm_info(get_name(), "Write Packet received in master driver", UVM_LOW)
                w_trans.print();
                fork
                    send_write_address();
                    send_write_data();
                join
                seq_item_port.item_done();
                w_done = 1;
            end
        end
        begin
            `uvm_info("DEBUG", $sformatf("r_addr(), r_done = %0d", r_done), UVM_DEBUG)
            if(r_done) begin
                r_done = 0;
                seq_item_port2.get_next_item(r_trans);
                `uvm_info(get_name(), "Read Packet received in master driver", UVM_LOW)
                r_trans.print();
                send_read_address();
                seq_item_port2.item_done();
                r_done = 1;
            end
        end
    join_none
endtask: drive

task axi_m_driver::send_write_address();
    `uvm_info("DEBUG", "Inside send_write_address()", UVM_HIGH)
    
    // Drive all the data
    @(vif.m_drv_cb);
    vif.m_drv_cb.AWID   <= w_trans.id;
    vif.m_drv_cb.AWADDR <= w_trans.addr;
    vif.m_drv_cb.AWLEN  <= w_trans.b_len;
    vif.m_drv_cb.AWSIZE <= w_trans.b_size;
    vif.m_drv_cb.AWBURST<= w_trans.b_type;
    `uvm_info("DEBUG", "Data Driven", UVM_HIGH)

    // Wait 1 cycle and drive AWVALID
    @(vif.m_drv_cb);
    AWVALID              = 1;
    vif.m_drv_cb.AWVALID<= AWVALID;
    `uvm_info("DEBUG", "Asserted AWVALID", UVM_HIGH)

    // Wait for AWREADY and deassert AWVALID
    @(vif.m_drv_cb);
    wait(vif.m_drv_cb.AWREADY);
    AWVALID              = 0;
    vif.m_drv_cb.AWVALID<= AWVALID;
    `uvm_info("DEBUG", "Deasserted AWVALID", UVM_HIGH)

    // Wait for write data channel to complete transaction
    wait(vif.m_drv_cb.BVALID);
endtask: send_write_address

task axi_m_driver::send_write_data();
    int len = w_trans.b_len + 1;
    temp = new[len];
    `uvm_info("DEBUG", "Inside send_write_data()", UVM_HIGH)
    foreach ( w_trans.data[i,j] ) begin
        temp[i][8*j+:8] = w_trans.data[i][j];
    end
    wait(AWVALID && vif.m_drv_cb.AWREADY);
    `uvm_info("DEBUG", "packed data", UVM_HIGH)
    for (int i=0; i<len; i++) begin
        `uvm_info("DEBUG", $sformatf("Inside loop: iter %0d", i), UVM_HIGH)
        @(vif.m_drv_cb);
        vif.m_drv_cb.WID    <= w_trans.id;
        vif.m_drv_cb.WDATA  <= temp[i];
        vif.m_drv_cb.WLAST  <= (i == len-1) ? 1:0;

        // Assert WVALID
        @(vif.m_drv_cb);
        vif.m_drv_cb.WVALID <= 1;

        // Wait for WREADY and deassert WVALID
        #1;
        wait(vif.m_drv_cb.WREADY);
        vif.m_drv_cb.WVALID <= 0;
        vif.m_drv_cb.WLAST  <= 0;
    end
    wait(vif.m_drv_cb.BVALID);
endtask: send_write_data


task axi_m_driver::send_read_address();
    // Send the read address and control signals
    @(vif.m_drv_cb);
    vif.m_drv_cb.ARID   <= r_trans.id;
    vif.m_drv_cb.ARADDR <= r_trans.addr;
    vif.m_drv_cb.ARLEN  <= r_trans.b_len;
    vif.m_drv_cb.ARSIZE <= r_trans.b_size;
    vif.m_drv_cb.ARBURST<= r_trans.b_type;

    // Assert ARVALID after one clock cycle
    @(vif.m_drv_cb);
    vif.m_drv_cb.ARVALID<= 1;

    // Wait for AWREADY and deassert AWVALID
    @(vif.m_drv_cb);
    wait(vif.m_drv_cb.ARREADY);
    vif.m_drv_cb.ARVALID<= 0;

    // Wait for RLAST signal before sending next address
    wait(vif.m_drv_cb.RLAST && vif.m_drv_cb.RVALID);
endtask: send_read_address