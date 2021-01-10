//  Class: axi_write_seq
//
class axi_write_seq#(D_WIDTH = 16, int A_WIDTH = 16) extends uvm_sequence;
    `uvm_object_param_utils(axi_write_seq#(data_width, addr_width));
    
    //  Group: Variables
    const int no_of_trans;
    bit[7:0] id;
    axi_transaction#(data_width, addr_width) trans;

    //  Constructor: new
    function new(string name = "axi_write_seq");
        super.new(name);
        no_of_trans = 20;
    endfunction: new

    //  Task: body
    //  This is the user-defined task where the main sequence code resides.
    extern virtual task body();
    
endclass: axi_write_seq

task axi_write_seq::body();
    repeat(no_of_trans) begin
        id++;
        trans = new("trans");
        trans.randomize();
        trans.id = {0, id};
        trans.print();
        #10;
    end
endtask: body
