//  Class: axi_read_seq
//
class axi_read_seq#(D_WIDTH = 16, A_WIDTH = 16) extends uvm_sequence;
    `uvm_object_param_utils(axi_read_seq#(D_WIDTH, A_WIDTH));
    
    //  Group: Variables
    const int no_of_trans;
    bit[7:0] id;
    axi_transaction#(D_WIDTH, A_WIDTH) trans;

    //  Constructor: new
    function new(string name = "axi_read_seq");
        super.new(name);
        no_of_trans = 20;
    endfunction: new

    //  Task: body
    //  This is the user-defined task where the main sequence code resides.
    extern virtual task body();
    
endclass: axi_read_seq

task axi_read_seq::body();
    repeat(no_of_trans) begin
        id++;
        trans = new("trans");
        trans.randomize();
        trans.id = {1, id};
        trans.print();
        #10;
    end
endtask: body
