// ******************** Global Parameters ******************
// Please change the A_WIDTH & D_WIDTH with the respective width
// of address and data bus
parameter A_WIDTH = 8;     // Address bus width
parameter D_WIDTH = 128;     // Data bus width

`include "axi_package.svh"
`include "axi_interface.sv"

module top;
    bit clk, rstn;

    always #5 clk = ~clk;

    initial rstn = 1;

    axi_intf#(.A_WIDTH(A_WIDTH), .D_WIDTH(D_WIDTH)) intf(clk, rstn);

    env_config env_cfg;

    initial begin
        env_cfg = new();
        env_cfg.intf = intf;
        uvm_config_db#(env_config)::set(null, "uvm_test_top", "config", env_cfg);
        uvm_config_db#(env_config)::set(null, "uvm_test_top.env.master", "config", env_cfg);
        uvm_config_db#(env_config)::set(null, "uvm_test_top.env.slave", "config", env_cfg);
        run_test("axi_base_test");
    end
    
endmodule