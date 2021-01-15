`uvm_analysis_imp_decl(_master)
`uvm_analysis_imp_decl(_slave)

class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)
    
    // Components
    uvm_analysis_imp_master#(axi_transaction#(D_WIDTH, A_WIDTH), axi_scoreboard) m_ap_imp;
    uvm_analysis_imp_slave#(axi_transaction#(D_WIDTH, A_WIDTH), axi_scoreboard) s_ap_imp;
    

    // Variables
    axi_transaction#(D_WIDTH, A_WIDTH) m_wtrans, m_rtrans, s_wtrans, s_rtrans;
    bit [1:0] w_rcvd, r_rcvd;
    int passCnt, failCnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    function void write_master(axi_transaction#(D_WIDTH, A_WIDTH) trans);
        if(trans.id[8]) begin
            m_rtrans = trans;
            r_rcvd[0] = 1;
        end
            
        else begin
            m_wtrans = trans;
            w_rcvd[0] = 1;
        end
        check();
    endfunction

    function void write_slave(axi_transaction#(D_WIDTH, A_WIDTH) trans);
        if(trans.id[8]) begin
            s_rtrans = trans;
            r_rcvd[1] = 1;
        end
            
        else begin
            s_wtrans = trans;
            w_rcvd[1] = 1;
        end
        check();
    endfunction

    function void check();
        if(w_rcvd == 2'b11) begin
            if(m_wtrans.compare(s_wtrans)) begin
                `uvm_info("SCB", $sformatf("ID %0d: PASSED", m_wtrans.id), UVM_NONE)
                passCnt++;
            end
            else begin
                `uvm_error("SCB", $sformatf("ID %0d: FAILED", m_wtrans.id))
                failCnt++;
            end
            w_rcvd = 2'b00;
        end

        if(r_rcvd == 2'b11) begin
            if(m_rtrans.compare(s_rtrans)) begin
                `uvm_info("SCB", $sformatf("ID %0d: PASSED", m_rtrans.id), UVM_NONE)
                passCnt++;
            end
            else begin
                `uvm_error("SCB", $sformatf("ID %0d: FAILED", m_rtrans.id))
                failCnt++;
            end
            r_rcvd = 2'b00;
        end
    endfunction

    //  Function: build_phase
    extern function void build_phase(uvm_phase phase);
    
endclass //axi_scoreboard extends uvm_scoreboard

function void axi_scoreboard::build_phase(uvm_phase phase);
    /*  note: Do not call super.build_phase() from any class that is extended from an UVM base class!  */
    /*  For more information see UVM Cookbook v1800.2 p.503  */
    //super.build_phase(phase);

    m_ap_imp = new("m_ap_imp", this);
    s_ap_imp = new("s_ap_imp", this);
endfunction: build_phase
