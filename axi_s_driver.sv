class axi_s_driver extends uvm_driver;
    `uvm_component_utils(axi_s_driver)
    
    // Components
    virtual axi_intf#(.D_WIDTH(D_WIDTH), .A_WIDTH(A_WIDTH)).SDRV vif;

    // Variables
    axi_transaction#(D_WIDTH, A_WIDTH) s_wtrans, s_rtrans;
    bit [7:0] mem [bit[A_WIDTH-1:0]];
    bit [A_WIDTH-1:0] w_addr, r_addr;
    bit w_done, r_done;
    

    // Methods
    extern task drive();
    extern task read_write_address();
    extern task read_read_address();
    extern task read_write_data();
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
    
endclass //axi_s_driver extends uvm_driver

function void axi_s_driver::build_phase(uvm_phase phase);
    s_wtrans = new("s_wtrans");
    s_rtrans = new("s_rtrans");
endfunction: build_phase

task axi_s_driver::run_phase(uvm_phase phase);
    vif.s_drv_cb.AWREADY    <= 1;
    vif.s_drv_cb.ARREADY    <= 1;
    vif.s_drv_cb.WREADY     <= 1;
    // vif.s_drv_cb.BVALID     <= 1;
    // vif.s_drv_cb.RLAST      <= 1;
    vif.s_drv_cb.RVALID     <= 1;
    vif.s_drv_cb.RDATA      <= 'b0;
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
                read_read_address();
                send_read_data();
                r_done = 1;
            end
        end
    join_none
endtask: drive

task axi_s_driver::read_write_address();
    `uvm_info("DEBUG_S", "Inside read_write_address", UVM_HIGH)
    wait(vif.s_drv_cb.AWVALID);
    s_wtrans.id     = vif.s_drv_cb.AWID;
    s_wtrans.addr   = vif.s_drv_cb.AWADDR;
    s_wtrans.b_size = vif.s_drv_cb.AWSIZE;
    s_wtrans.b_type = B_TYPE'(vif.s_drv_cb.AWBURST);
    s_wtrans.b_len  = vif.s_drv_cb.AWLEN;

    s_wtrans.print();
endtask: read_write_address

task axi_s_driver::read_write_data();
    int addr_1, addr_n, addr_align;
    int lower_byte_lane, upper_byte_lane, upper_wrap_boundary, lower_wrap_boundary;
    int no_bytes, total_bytes;
    bit isAligned;
    int c;
    bit err, align_err;
    `uvm_info("DEBUG_S", "Inside read_write_data", UVM_HIGH)
    vif.s_drv_cb.BVALID     <= 0;
    
    // Initial values and calculations
    addr_1 = s_wtrans.addr;
    no_bytes = 2**s_wtrans.b_size;
    total_bytes = no_bytes * (s_wtrans.b_len+1);
    addr_align = int'(addr_1/no_bytes)*no_bytes;
    `uvm_info("DEBUG_S", $sformatf("Calculated aligned addr %0d", addr_align), UVM_HIGH)
    isAligned = addr_1 == addr_align;

    // Calculate boundaries for WRAP Burst
    if(s_wtrans.b_type == WRAP) begin
        lower_wrap_boundary = int'(addr_1/total_bytes)*total_bytes;
        upper_wrap_boundary = lower_wrap_boundary + total_bytes;
        `uvm_info("DEBUG_S", $sformatf("Calculated Lower Wrap Boundary: %0d", lower_wrap_boundary), UVM_HIGH)
        `uvm_info("DEBUG_S", $sformatf("Calculated Upper Wrap Boundary: %0d", upper_wrap_boundary), UVM_HIGH)
    end

    // check whether the wrap burst is alligned or not
    if(s_wtrans.b_type == WRAP && !isAligned)
        align_err = 1;

    // Store data
    err = 0;
    for (int i=0; i<s_wtrans.b_len+1; i++) begin
        `uvm_info("DEBUG_S", "Inside read_data_loop", UVM_HIGH)
        // addr_n = addr_align + i*no_bytes;
        
        // Lane selection for the first transfer. In case of unaligned transfer the bytes b/w the 
        // start address and aligned address is not transferred. Thus for an unaligned burst, the
        // first transfer has less bytes and the actual burst size;
        // 'c' is a variable which stores which byte lane to select. In AXI, valid byte lane is used and
        // selected dynamically using lower_byte_lane and upper_byte_lane, but we for simplicity, we are
        // sending the data starting from WDATA[0:8*2**b_size], thus c converts the lower_byte_lane to 
        // such that it always select the data lines within the valid byte lanes, i.e. [0:8*2**b_size]
        // This can be changed in future to match with proper AXI protocol
        if(i==0 || s_wtrans.b_type == FIXED) begin
            lower_byte_lane = addr_1-int'(addr_1/(D_WIDTH/8))*(D_WIDTH/8);
            upper_byte_lane = addr_align+no_bytes-1-int'(addr_1/(D_WIDTH/8))*(D_WIDTH/8);
            addr_n = addr_1;
            c = isAligned ? 0 : lower_byte_lane;
            while (c>=no_bytes) begin
                c -= no_bytes;
            end
        end
        // For 2nd and all other transfers the address is always alligned and thus can read the entire 
        // valid byte lane, i.e, [0:8*2**b_size]; and thus c always start with 0
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
        err = 0;
        for (int j=lower_byte_lane; j<=upper_byte_lane; j++) begin
            if(addr_n+j-lower_byte_lane >= 2**A_WIDTH)
                err = 1;
            if(err || align_err)
                continue;
            mem[addr_n+j-lower_byte_lane] = vif.s_drv_cb.WDATA[8*c+:8];
            `uvm_info("DEBUG_S", $sformatf("c is %0d, addr is %0d, stored value is %h", c, addr_n+j-lower_byte_lane, mem[addr_n+j-lower_byte_lane]), UVM_HIGH)
            c++;
            c = c>=no_bytes ? 0:c;
        end

        // Update address
        if(s_wtrans.b_type != FIXED) begin
            if(isAligned) begin
                addr_n = addr_n+no_bytes;
                if(s_wtrans.b_type == WRAP) begin
                    `uvm_info("DEBUG_S", $sformatf("Updated addrn before boundary check: %0d", addr_n), UVM_HIGH)
                    addr_n = addr_n>=upper_wrap_boundary ? lower_wrap_boundary : addr_n;
                    `uvm_info("DEBUG_S", $sformatf("Updated addrn after boundary check: %0d", addr_n), UVM_HIGH)
                end
            end
            else begin
                addr_n = addr_align + no_bytes;
                isAligned = 1;
            end
        end
        @(vif.s_drv_cb);
    end
    vif.s_drv_cb.BID        <= s_wtrans.id;
    if(err || align_err)
        vif.s_drv_cb.BRESP  <= 2'b01;
    else
        vif.s_drv_cb.BRESP  <= 2'b00;
    @(vif.s_drv_cb);
    vif.s_drv_cb.BVALID <= 1;
    @(vif.s_drv_cb);
    wait(vif.s_drv_cb.BREADY)
    vif.s_drv_cb.BVALID <= 0;
endtask: read_write_data

task axi_s_driver::read_read_address();
    `uvm_info("DEBUG_S", "Inside read_write_address", UVM_HIGH)
    wait(vif.s_drv_cb.ARVALID);
    s_rtrans.id     = vif.s_drv_cb.ARID;
    s_rtrans.addr   = vif.s_drv_cb.ARADDR;
    s_rtrans.b_size = vif.s_drv_cb.ARSIZE;
    s_rtrans.b_type = B_TYPE'(vif.s_drv_cb.ARBURST);
    s_rtrans.b_len  = vif.s_drv_cb.ARLEN;

    s_rtrans.print();
endtask: read_read_address

task axi_s_driver::send_read_data();
    int addr_1, addr_n, addr_align;
    int lower_byte_lane, upper_byte_lane, upper_wrap_boundary, lower_wrap_boundary;
    int no_bytes, total_bytes;
    bit isAligned;
    int c;
    bit err;
    `uvm_info("DEBUG_S", "Inside send_write_data", UVM_HIGH)
    addr_1 = s_rtrans.addr;
    no_bytes = 2**s_rtrans.b_size;
    total_bytes = no_bytes * (s_rtrans.b_len+1);

    // Calculate align address
    addr_align = int'(addr_1/no_bytes)*no_bytes;
    `uvm_info("DEBUG_S", $sformatf("Calculated aligned addr %0d", addr_align), UVM_HIGH)
    isAligned = addr_1 == addr_align;

    // If WRAP Burst then calculate the wrap boundary
    if(s_rtrans.b_type == WRAP) begin
        lower_wrap_boundary = int'(addr_1/total_bytes)*total_bytes;
        upper_wrap_boundary = lower_wrap_boundary + total_bytes;
        `uvm_info("DEBUG_S", $sformatf("Calculated Lower Wrap Boundary: %0d", lower_wrap_boundary), UVM_HIGH)
        `uvm_info("DEBUG_S", $sformatf("Calculated Upper Wrap Boundary: %0d", upper_wrap_boundary), UVM_HIGH)
    end

    // Initial signals
    vif.s_drv_cb.RLAST  <= 0;
    vif.s_drv_cb.RVALID <=0;
    vif.s_drv_cb.RID    <= s_rtrans.id;

    // Store data
    for (int i=0; i<s_rtrans.b_len+1; i++) begin
        `uvm_info("DEBUG_S", "Inside send_data_loop", UVM_HIGH)
        // addr_n = addr_align + i*no_bytes;
        
        // Lane selection for the first transfer. In case of unaligned transfer the bytes b/w the 
        // start address and aligned address is not transferred. Thus for an unaligned burst, the
        // first transfer has less bytes and the actual burst size;
        // 'c' is a variable which stores which byte lane to select. In AXI, valid byte lane is used and
        // selected dynamically using lower_byte_lane and upper_byte_lane, but we for simplicity, we are
        // sending the data starting from WDATA[0:8*2**b_size], thus c converts the lower_byte_lane to 
        // such that it always select the data lines within the valid byte lanes, i.e. [0:8*2**b_size]
        // This can be changed in future to match with proper AXI protocol
        if(i==0 || s_rtrans.b_type == FIXED) begin
            lower_byte_lane = addr_1-int'(addr_1/(D_WIDTH/8))*(D_WIDTH/8);
            upper_byte_lane = addr_align+no_bytes-1-int'(addr_1/(D_WIDTH/8))*(D_WIDTH/8);
            addr_n = addr_1;
            c = isAligned ? 0 : lower_byte_lane;
            while (c>=no_bytes) begin
                c -= no_bytes;
            end
        end
        // For 2nd and all other transfers the address is always alligned and thus can read the entire 
        // valid byte lane, i.e, [0:8*2**b_size]; and thus c always start with 0
        else begin
            lower_byte_lane = addr_n-int'(addr_n/(D_WIDTH/8))*(D_WIDTH/8);
            upper_byte_lane = lower_byte_lane + no_bytes-1;
            c = 0;
        end

        // @(vif.s_drv_cb);
        `uvm_info("DEBUG_S", $sformatf("lower_byte_lane is %0d", lower_byte_lane), UVM_HIGH)
        `uvm_info("DEBUG_S", $sformatf("upper_byte_lane is %0d", upper_byte_lane), UVM_HIGH)
        `uvm_info("DEBUG_S", $sformatf("addr_n is %0d", addr_n), UVM_HIGH)
        // Follows little endian
        err = 0;
        for (int j=lower_byte_lane; j<=upper_byte_lane; j++) begin
            if(!mem.exists(addr_n+j-lower_byte_lane)) begin
                err = 1;
                vif.s_drv_cb.RDATA[8*c+:8] <= 'b0;
                `uvm_info("DEBUG_S", $sformatf("c is %0d, addr is %0d, No data in location", c, addr_n+j-lower_byte_lane), UVM_HIGH)
            end
            else begin
                vif.s_drv_cb.RDATA[8*c+:8] <= mem[addr_n+j-lower_byte_lane];
                `uvm_info("DEBUG_S", $sformatf("c is %0d, addr is %0d, stored value is %h", c, addr_n+j-lower_byte_lane, mem[addr_n+j-lower_byte_lane]), UVM_HIGH)
            end
            c++;
            c = c>=no_bytes ? 0:c;
        end

        if(i == s_rtrans.b_len) begin
            vif.s_drv_cb.RLAST <= 1;
        end
            

        if(err)
            vif.s_drv_cb.RRESP <= 2'b01;
        else
            vif.s_drv_cb.RRESP <= 2'b00;
        
        @(vif.s_drv_cb);
        vif.s_drv_cb.RVALID <= 1;

        // Update address
        if(s_rtrans.b_type != FIXED) begin
            if(isAligned) begin
                addr_n = addr_n+no_bytes;
                if(s_rtrans.b_type == WRAP) begin
                    `uvm_info("DEBUG_S", $sformatf("Updated addrn before boundary check: %0d", addr_n), UVM_HIGH)
                    addr_n = addr_n>=upper_wrap_boundary ? lower_wrap_boundary : addr_n;
                    `uvm_info("DEBUG_S", $sformatf("Updated addrn after boundary check: %0d", addr_n), UVM_HIGH)
                end
            end
            else begin
                addr_n = addr_align + no_bytes;
                isAligned = 1;
            end
        end
        @(vif.s_drv_cb);
        wait(vif.s_drv_cb.RREADY);
        vif.s_drv_cb.RVALID <= 0;
    end
endtask: send_read_data
