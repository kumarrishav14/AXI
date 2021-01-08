import uvm_pkg::*;

//  Class: axi_transaction
//
class axi_transaction#(int d_width = 16, int a_width = 16) extends uvm_sequence_item;
    typedef axi_transaction this_type_t;
    `uvm_object_utils(axi_transaction);

    //  Group: Variables
    bit [8:0] id;
    rand bit [a_wdith-1:0] addr;
    rand bit [8:0] data [][];
    rand bit [2:0] b_size;
    rand bit [3:0] b_len;
    rand bit [1:0] b_type;
    bit [1:0] b_resp;
    bit [1:0] r_resp [];

    //  Group: Constraints
    constraint b_size_val { 8*(2^b_size) <= d_width; }

    constraint data_size {
        /*  solve order constraints  */
        solve b_len before data;
        solve b_size before data;

        /*  rand variable constraints  */
        data.size() == b_len;
        foreach ( data[i] ) begin
            data[i].size() == 2^b_size;
        end
    }

    constraint b_len_val {
        /*  rand variable constraints  */
        b_len inside { 1, 2, 4, 8, 16, 32, 64, 128, 256 };
    }
    
    constraint b_type_val {
        /*  rand variable constraints  */
        b_type inside { [0:2] };
    }
    
    //  Group: Functions

    //  Constructor: new
    function new(string name = "axi_transaction");
        super.new(name);
    endfunction: new

    //  Function: do_copy
    // extern function void do_copy(uvm_object rhs);
    //  Function: do_compare
    // extern function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    //  Function: convert2string
    // extern function string convert2string();
    //  Function: do_print
    // extern function void do_print(uvm_printer printer);
    //  Function: do_record
    // extern function void do_record(uvm_recorder recorder);
    //  Function: do_pack
    // extern function void do_pack();
    //  Function: do_unpack
    // extern function void do_unpack();
    
endclass: axi_transaction


/*----------------------------------------------------------------------------*/
/*  Constraints                                                               */
/*----------------------------------------------------------------------------*/




/*----------------------------------------------------------------------------*/
/*  Functions                                                                 */
/*----------------------------------------------------------------------------*/

