<style>
    h3 {
        font-weight: bold;
        color: #39833b;
    }
    figure {
      padding: 4px;
      margin: auto;
      text-align: center;
    }
    
    :nav {
        margin-left: 10px;
    }

    figcaption {
      color: rgba(0, 134, 125, 0.938);
      font-style: italic;
      padding: 2px;
      text-align: center;
    }

    table {
        margin-left: auto;
        margin-right: auto;
        width: auto;
    }
    th {
        border: 1px solid #28632a;
        border-bottom: 2px solid black;
        background-color: #4CAF50;
        color: white;
        padding: 10px 40px;
        text-align: center;
    }

    td {
        border: 1px solid black;
    }
</style>

<p class="nav"><a href="#how-to-run-test-bench">How to run test bench</a>&emsp;|&emsp;<a href="#architecture">Testbench Achitecture</a>&emsp;|&emsp;<a href="#components">Components</a> </p>

# How to run test bench

- Download the latest release from below or visit the [release page](https://github.com/kumarrishav14/AXI/releases) for more releases.
    <table align="center">
        <thead>
        <tr>
            <th>Testbench</th>
        </tr>
        </thead>
        <tbody>
        <tr align="center">
            <td>
                <a href="https://github.com/kumarrishav14/AXI/archive/v1.0.zip">Zip</a>
            </td>
        </tr>
        <tr align="center">
            <td>
                <a href="https://github.com/kumarrishav14/AXI/archive/v1.0.tar.gz">Tar.gz</a>
            </td>
        </tr>
        </tbody>
    </table>

<p>
    &NewLine;
</p>

- Copy the contents in a folder.
- Compile *tb_top.sv* in any simulator and simulate *top* module.
- Test suite includes base test along with 5 directed test cases.



# Testbench Details

## Architecture

<figure>
    <img src="images/AXI.png"/>
    <figcaption><b>Fig. 1:</b> Testbench Architecture</figcaption>
</figure>

## Components

### **Transaction**

Signals encapsulated in transaction class is shown below:

```sv
class axi_transaction#(d_width = 16, a_width = 16) extends uvm_sequence_item;

    //  Group: Variables
    bit [8:0] id;
    rand bit [a_width-1:0] addr;
    rand bit [7:0] data [][];
    rand bit [2:0] b_size;
    rand bit [3:0] b_len;
    rand B_TYPE b_type;
    bit b_last;
    bit [1:0] b_resp;
    bit [1:0] r_resp [];
endclass
```

- `id` is a 9 bit field. 8 bit holds the count of the transaction, and the 9th bit is 0 for write transactions and 1 for read transactions.
-  `data[][]` is a 2 dimensional dynamic array which stores data for transaction. `size = AWLEN, 2**AWSIZE`
- `B_TYPE` is a enum which has values `{FIXED, INCR, WRAP}`. Represents various burst modes.

Transaction class also has various constraints as per the AXI specifications and for directed cases.

Transaction class also encapsulates helper function like `do_print()`, `do_compare(axi_transaction rhs)`, `do_copy(axi_transaction rhs)` etc.

### **Sequence**

Generates new packet which is sent to the driver. Two sequences are used in this VIP to implement parallel read and write operations of AXI. 
- Write Sequence - Generates write transaction which is sent to write sequencer. Driver uses the packet from this sequencer to drive the write channels, i.e, _Write Address Channel_, _Write Data Channel_ and read the response from _Burst Response Channel_.

- Read Sequence - Generates read transaction which is sent to read sequencer. Driver uses the packet from this sequencer to drive the _Read Address channels_, and read the data & response from _Read Data Channel_.


### Master

#### **Sequencer**

In AXI, the read and write channels have **no dependency** on each other and thus 2 sequencers are used to properly simulate this behaviour. Both the sequncers run in parallel in 2 different processes and driver can accept packets from any or both of these seqeuncer without any dependency.
- Write Sequencer - Sends write transaction received from write sequence to the driver. 
- Read Sequencer - Sends read transaction received from read sequence to the driver.

#### **Driver**

Driver runs 2 processes in parallel, one to receive the packet from write seqeuncer and drive the write transaction, and the other process to receive the packet from read sequencer and drive the read transaction.

#### **Monitor**

Monitors the interface from the Master side, thus acts as input monitor for _Write Address Channel_, _Write Data Channel_ & _Read Address channels_, and output monitor for _Read Data Channel_ & _Burst Response Channel_.

### Slave

#### **Driver**

Slave driver decodes the address and stores received data in an associative array. Address decoding supports both aligned and unaligned transfers.

Error Response:
- When unaligned address is given for wrap transaction (As it is against AXI specifications)
- If for read transaction, there is no data in given address
- When the given address or calculated address is out of bounds

_In this version, slave driver doesnot support byte_lane_selection, it assumes for each transfer data starts from 0 bit of data bus, but it can ignore data bytes in case of unaligned transfer as mentioned in AXI specifications_.

#### **Monitor**

Monitors the interface from the slave side, thus acts as output monitor for _Write Address Channel_, _Write Data Channel_ & _Read Address channels_, and input monitor for _Read Data Channel_ & _Burst Response Channel_.

### **Scoreboard**

Compares packet received from master and slave monitor and compares it. Packet having same ID's are compared and log is created.


**_This project is governed by [MIT License](LICENSE)_**
