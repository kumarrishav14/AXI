
class axi_base_test extends uvm_test;
    `uvm_component_utils(axi_base_test)
    
    // Components
    axi_env env;
    axi_write_seq#(.D_WIDTH(D_WIDTH), .A_WIDTH(A_WIDTH)) wr_seq;
    axi_read_seq#(.D_WIDTH(D_WIDTH), .A_WIDTH(A_WIDTH)) rd_seq;

    // variables
    env_config env_cfg;
    test_config test_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        test_cfg = new("test_cfg");
        test_cfg.no_write_cases = 20;
        test_cfg.no_read_cases = 20;
    endfunction //new()

    //  Function: build_phase
    extern function void build_phase(uvm_phase phase);
    
    //  Function: end_of_elaboration_phase
    extern function void end_of_elaboration_phase(uvm_phase phase);
    
    //  Function: run_phase
    extern task run_phase(uvm_phase phase);
    
endclass //axi_base_test extends uvm_test

function void axi_base_test::build_phase(uvm_phase phase);
    test_cfg.burst_type = -1;
    uvm_config_db#(test_config)::set(null, "uvm_test_top.seq", "config", test_cfg);
    
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


// ****************************************************************************************
//                                  Directed Test Cases
// ****************************************************************************************
class axi_write_test extends axi_base_test;
    `uvm_component_utils(axi_write_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);  
    endfunction: build_phase

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
    endfunction: end_of_elaboration_phase
    
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        wr_seq.start(env.master.w_seqr);
        phase.drop_objection(this);
    endtask: run_phase
endclass //write_test extends axi_base_test

class axi_read_test extends axi_base_test;
    `uvm_component_utils(axi_read_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);  
    endfunction: build_phase

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
    endfunction: end_of_elaboration_phase
    
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        wr_seq.start(env.master.w_seqr);
        rd_seq.start(env.master.r_seqr);
        phase.drop_objection(this);
    endtask: run_phase
endclass //write_test extends axi_base_test

class axi_fixed_test extends axi_base_test;
    `uvm_component_utils(axi_fixed_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        test_cfg.burst_type = 0;
        uvm_config_db#(test_config)::set(null, "uvm_test_top.seq", "config", test_cfg);
        
        wr_seq = new("wr_seq");
        rd_seq = new("rd_seq");
        env = axi_env::type_id::create("env", this);
    endfunction: build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask: run_phase
endclass //axi_fixed_test extends axi_base_test

class axi_incr_test extends axi_base_test;
    `uvm_component_utils(axi_incr_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        test_cfg.burst_type = 1;
        uvm_config_db#(test_config)::set(null, "uvm_test_top.seq", "config", test_cfg);
        
        wr_seq = new("wr_seq");
        rd_seq = new("rd_seq");
        env = axi_env::type_id::create("env", this);
    endfunction: build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask: run_phase
endclass //axi_fixed_test extends axi_base_test

class axi_wrap_test extends axi_base_test;
    `uvm_component_utils(axi_wrap_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        test_cfg.burst_type = 2;
        uvm_config_db#(test_config)::set(null, "uvm_test_top.seq", "config", test_cfg);
        
        wr_seq = new("wr_seq");
        rd_seq = new("rd_seq");
        env = axi_env::type_id::create("env", this);
    endfunction: build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask: run_phase
endclass //axi_fixed_test extends axi_base_test
