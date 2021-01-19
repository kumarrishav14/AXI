interface axi_intf #(parameter A_WIDTH = 16, D_WIDTH = 16)(input bit clk, bit rstn);
    // Write Address
    logic [8:0] AWID;
    logic [A_WIDTH-1:0] AWADDR;
    logic [3:0] AWLEN;
    logic [2:0] AWSIZE;
    logic [1:0] AWBURST;
    logic AWVALID, AWREADY;

    // Write Data
    logic [8:0] WID;
    logic [D_WIDTH-1:0] WDATA;
    logic [(D_WIDTH/8)-1:0] WSTRB;
    logic WLAST, WVALID, WREADY;

    // Write Response
    logic [8:0] BID;
    logic [1:0] BRESP;
    logic BVALID, BREADY;

    // Read Address
    logic [8:0] ARID;
    logic [A_WIDTH-1:0] ARADDR;
    logic [3:0] ARLEN;
    logic [2:0] ARSIZE;
    logic [1:0] ARBURST;
    logic ARVALID, ARREADY;

    // Read Data
    logic [8:0] RID;
    logic [D_WIDTH-1:0] RDATA;
    logic [1:0] RRESP;
    logic RLAST, RVALID, RREADY;

    /* Clocking Blocks: 3 CBs are defined as follows
            1. m_drv_cb - Clocking block for master driver
            2. s_drv_cb - Clocking block for slave driver
            3. mon_cb   - Clocking block for monitors of both master and slave */
    clocking m_drv_cb @(posedge clk);
        output AWID, AWADDR, AWLEN, AWSIZE, AWBURST,AWVALID, WID, WDATA, WSTRB, WLAST, WVALID, 
                BREADY, ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARVALID, RREADY;
        input AWREADY, WREADY, BID, BRESP, BVALID, ARREADY, RID, RDATA, RRESP, RLAST, RVALID;
    endclocking

    clocking mon_cb @(posedge clk);
        input AWID, AWADDR, AWLEN, AWSIZE, AWBURST,AWVALID, WID, WDATA, WSTRB, WLAST, WVALID, 
                BREADY, ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARVALID, RREADY;
        input AWREADY, WREADY, BID, BRESP, BVALID, ARREADY, RID, RDATA, RRESP, RLAST, RVALID;
    endclocking

    clocking s_drv_cb @(posedge clk);
        input AWID, AWADDR, AWLEN, AWSIZE, AWBURST,AWVALID, WID, WDATA, WSTRB, WLAST, WVALID, 
                BREADY, ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARVALID, RREADY;
        output AWREADY, WREADY, BID, BRESP, BVALID, ARREADY, RID, RDATA, RRESP, RLAST, RVALID;
    endclocking

    modport MDRV(clocking m_drv_cb, input rstn);
    modport MMON(clocking mon_cb,   input rstn);
    modport SDRV(clocking s_drv_cb, input rstn);
    modport SMON(clocking mon_cb,   input rstn);

    // *************************************************************************************************
    //                                      Assertions
    // *************************************************************************************************
    // Property to check whether all write address channel remains stable after AWVALID is asserted
    property aw_valid;
        @(posedge clk) $rose(AWVALID) |-> ( $stable(AWID)   
                                            &&$stable(AWADDR)
                                            &&$stable(AWLEN)
                                            &&$stable(AWSIZE) 
                                            &&$stable(AWBURST)) throughout AWREADY[->1];
    endproperty

    // Property to check whether all write address channel remains stable after AWVALID is asserted
    property w_valid;
        @(posedge clk) $rose(WVALID) |-> (  $stable(WID) 
                                            && $stable(WDATA)
                                            && $stable(WSTRB)
                                            && $stable(WLAST)) throughout WREADY[->1];
    endproperty

    // Property to check whether all write address channel remains stable after AWVALID is asserted
    property b_valid;
        @(posedge clk) $rose(BVALID) |-> (  $stable(BID) 
                                            && $stable(BRESP)) throughout BREADY[->1];
    endproperty

    // Property to check whether all write address channel remains stable after AWVALID is asserted
    property ar_valid;
        @(posedge clk) $rose(ARVALID) |-> ( $stable(ARID)   
                                            &&$stable(ARADDR)
                                            &&$stable(ARLEN)
                                            &&$stable(ARSIZE) 
                                            &&$stable(ARBURST)) throughout ARREADY[->1];
    endproperty

    // Property to check whether all write address channel remains stable after AWVALID is asserted
    property r_valid;
        @(posedge clk) $rose(RVALID) |-> (  $stable(RID) 
                                            && $stable(RDATA)
                                            && $stable(RRESP)
                                            && $stable(RLAST)) throughout RREADY[->1];
    endproperty

    assert property (aw_valid);
    assert property (w_valid);
    assert property (b_valid);
    assert property (ar_valid);
    assert property (r_valid);
endinterface //axi_intf