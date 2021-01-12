class axi_s_driver extends uvm_driver;
    `uvm_component_utils(axi_s_driver)
    
    // Components
    virtual axi_intf#(.D_WIDTH(D_WIDTH), .A_WIDTH(A_WIDTH)).SDRV vif;

    // Variables
    axi_transaction#(D_WIDTH, A_WIDTH) s_wtrans, s_rtrans;
    bit [7:0] mem [bit[A_WIDTH-1:0]];
    bit [A_WIDTH-1:0] w_addr, r_addr;
    bit w_done, r_done;
    int addr_1, addr_n, addr_align, lower_byte_lane, upper_byte_lane;
    int no_bytes;
    bit isAligned;

    // Methods
    extern task drive();
    extern task read_write_address();
    // extern task read_read_address();
    extern task read_write_data();
    // extern task send_read_data();

    function new(string name, uvm_component parent);
        super.new(name, parent);
        w_done = 1;
    endfunction //new()

    //  Function: build_phase
    extern function void build_phase(uvm_phase phase);
    
    //  Function: run_phase
    extern task run_phase(uvm_phase phase);
    
endclass //axi_s_driver extends uvm_driver

function void axi_s_driver::build_phase(uvm_phase phase);
    s_wtrans = new("s_wtrans");
    s_rtrans = new("s_rtrans");
endfunction: build_phase

task axi_s_driver::run_phase(uvm_phase phase);
    vif.s_drv_cb.AWREADY    <= 1;
    vif.s_drv_cb.ARREADY    <= 1;
    vif.s_drv_cb.WREADY     <= 1;
    vif.s_drv_cb.BVALID     <= 1;
    vif.s_drv_cb.RLAST      <= 1;
    vif.s_drv_cb.RVALID     <= 1;
    forever begin
        @(vif.s_drv_cb);
        drive();
    end
endtask: run_phase

task axi_s_driver::drive();
    if(!vif.rstn) begin
        vif.s_drv_cb.RVALID <= 0;
        vif.s_drv_cb.BVALID <= 0;
        return;
    end
    fork
        begin
            // `uvm_info("DEBUG_S", $sformatf("w_addr(), w_done = %0d", w_done), UVM_HIGH)
            if(w_done) begin
                w_done = 0;
                read_write_address();
                read_write_data();
                w_done = 1;
            end
        end
        begin
            // `uvm_info("DEBUG_S", $sformatf("r_addr(), r_done = %0d", r_done), UVM_HIGH)
            if(r_done) begin
                r_done = 0;
                // read_read_address();
                r_done = 1;
            end
        end
    join_none
endtask: drive

task axi_s_driver::read_write_address();
    `uvm_info("DEBUG_S", "Inside read_write_address", UVM_HIGH)
    //has_valid_addr = 0;
    wait(vif.s_drv_cb.AWVALID);
    s_wtrans.addr    = vif.s_drv_cb.AWADDR;
    s_wtrans.b_size  = vif.s_drv_cb.AWSIZE;
    s_wtrans.b_type  = B_TYPE'(vif.s_drv_cb.AWBURST);
    s_wtrans.b_len   = vif.s_drv_cb.AWLEN;
    // has_valid_addr = 1;
    
    // if(vif.s_drv_cb.AWVALID) begin
    //     s_wtrans.addr    = vif.s_drv_cb.AWADDR;
    //     s_wtrans.b_size  = vif.s_drv_cb.AWSIZE;
    //     s_wtrans.b_type  = B_TYPE'(vif.s_drv_cb.AWBURST);
    //     s_wtrans.b_len   = vif.s_drv_cb.AWLEN;
    //     // has_valid_addr = 1;
    // end
    s_wtrans.print();
endtask: read_write_address

// ISSUES::
// 1. Proper byte lane selection not happening for 1st transfer in case of unaligned address
// 2. Implement for WARP
task axi_s_driver::read_write_data();
    int c;
    `uvm_info("DEBUG_S", "Inside read_write_data", UVM_HIGH)
    addr_1 = s_wtrans.addr;
    no_bytes = 2**s_wtrans.b_size;
    // Calculate align address
    if(s_wtrans.b_type == WARP)
        addr_align = int'(addr_1/(no_bytes*s_wtrans.b_len))*(no_bytes*s_wtrans.b_len);
    else
        addr_align = int'(addr_1/no_bytes)*no_bytes;
    `uvm_info("DEBUG_S", $sformatf("Calculated aligned addr %0d", addr_align), UVM_HIGH)
    isAligned = addr_1 == addr_align;
    // Store data
    for (int i=0; i<s_wtrans.b_len+1; i++) begin
        `uvm_info("DEBUG_S", "Inside read_data_loop", UVM_HIGH)
        addr_n = addr_align + i*no_bytes;
        
        
        if(i==0) begin
            lower_byte_lane = addr_1-int'(addr_1/(D_WIDTH/8))*(D_WIDTH/8);
            upper_byte_lane = addr_align+no_bytes-1-int'(addr_1/(D_WIDTH/8))*(D_WIDTH/8);
            addr_n = addr_1;
            c = isAligned ? 0 : lower_byte_lane;
        end
        else begin
            lower_byte_lane = addr_n-int'(addr_n/(D_WIDTH/8))*(D_WIDTH/8);
            upper_byte_lane = lower_byte_lane + no_bytes-1;
            c = 0;
        end
        `uvm_info("DEBUG_S", $sformatf("lower_byte_lane is %0d", lower_byte_lane), UVM_HIGH)
        `uvm_info("DEBUG_S", $sformatf("upper_byte_lane is %0d", upper_byte_lane), UVM_HIGH)
        `uvm_info("DEBUG_S", $sformatf("addr_n is %0d", addr_n), UVM_HIGH)
        wait(vif.s_drv_cb.WVALID);
        // Follows little endian
        for (int j=lower_byte_lane; j<=upper_byte_lane; j++) begin
            mem[addr_n+j-lower_byte_lane] = vif.s_drv_cb.WDATA[8*c+:8];
            `uvm_info("DEBUG_S", $sformatf("c is %0d, addr is %0d, stored value is %h", c, addr_n+j-lower_byte_lane, mem[addr_n+j-lower_byte_lane]), UVM_HIGH)
            c++;
            c = c>=no_bytes ? 0:c;
        end
        @(vif.s_drv_cb);
    end
endtask: read_write_data
