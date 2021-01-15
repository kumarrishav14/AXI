class axi_base_test extends uvm_test;
    `uvm_component_utils(axi_base_test)
    
    // Components
    axi_env env;
    axi_write_seq#(.D_WIDTH(D_WIDTH), .A_WIDTH(A_WIDTH)) wr_seq;
    axi_read_seq#(.D_WIDTH(D_WIDTH), .A_WIDTH(A_WIDTH)) rd_seq;

    // variables
    env_config env_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    //  Function: build_phase
    extern function void build_phase(uvm_phase phase);
    
    //  Function: end_of_elaboration_phase
    extern function void end_of_elaboration_phase(uvm_phase phase);
    
    //  Function: run_phase
    extern task run_phase(uvm_phase phase);
    
endclass //axi_base_test extends uvm_test

function void axi_base_test::build_phase(uvm_phase phase);
    /*  note: Do not call super.build_phase() from any class that is extended from an UVM base class!  */
    /*  For more information see UVM Cookbook v1800.2 p.503  */
    //super.build_phase(phase);

    wr_seq = new("wr_seq");
    rd_seq = new("rd_seq");
    env = axi_env::type_id::create("env", this);
endfunction: build_phase

function void axi_base_test::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    uvm_top.print_topology();
endfunction: end_of_elaboration_phase

task axi_base_test::run_phase(uvm_phase phase);
    phase.raise_objection(this);
    fork
        wr_seq.start(env.master.w_seqr);
        begin
            #200;
            rd_seq.start(env.master.r_seqr);
        end
    join
    phase.drop_objection(this);
endtask: run_phase


