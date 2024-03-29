\m5_TLV_version 1d --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
\m5
   use(m5-1.0)
   
   
   // #################################################################
   // #                                                               #
   // #  Starting-Point Code for MEST Course Tiny Tapeout Calculator  #
   // #                                                               #
   // #################################################################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   // To build within Makerchip for the FPGA or ASIC:
   //   o Use first line of file: \m5_TLV_version 1d --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
   //   o set(MAKERCHIP, 0)
   //   o var(target, FPGA)  // or ASIC
   set(MAKERCHIP, 0)
   var(my_design, tt_um_fpga_hdl_demo)
   var(target, ASIC)  /// FPGA or ASIC
   //-------------------------------------------------------
   
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_neq(m5_MAKERCHIP, 1): Debounce unless in Makerchip.
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_eq(m5_MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/35e36bd144fddd75495d4cbc01c4fc50ac5bde6f/tlv_lib/tiny_tapeout_lib.tlv'])


\TLV calc()
   
   // Sequential Calculator
   |calc
      @0
         $reset = *reset;
         $op[2:0] = *ui_in[6:4];
         $val2[7:0] = {4'b0, *ui_in[3:0]};
         $equals_in = *ui_in[7];
      @1
         
         //Count
         
         $valid = $reset ? 0 : $equals_in && ! >>1$equals_in;
      ?$valid   
         
         @1
            //Define values and operations
         
            $val1[7:0] = >>2$out[7:0];
            $quot[7:0] = $val1[7:0] / $val2[7:0];
            $prod[7:0] = $val1[7:0] * $val2[7:0];
            $diff[7:0] = $val1[7:0] - $val2[7:0];
            $sum[7:0] = $val1[7:0] + $val2[7:0];
         
      @2   
         //Determine output based on inputs
         
         $out[7:0] = $reset ? 8'b0 :
               ! $valid 
                 ? >>1$out[7:0] :
               $op == 3'b011 
                 ? $quot[7:0] :
               $op == 3'b010 
                 ? $prod[7:0] :
               $op == 3'b001 
                 ? $diff[7:0] :
               $op == 3'b100
                 ? >>2$mem :
               $op == 3'b000
                 ? $sum[7:0] :
               // else
                   >>1$out;
         
         
         //Memory MUX
         
         $mem[7:0] = $reset ? 8'b0 :
                        $op == 3'b101 && $valid
                           ? >>2$out :
                        //else
                           >>1$mem;
         
         
      @3   
         //VIZ
         $digit[3:0] = $out[3:0];
         *uo_out = $digit == 4'h0 ? 8'b00111111
                   : $digit == 4'h1 ? 8'b00000110
                   : $digit == 4'h2 ? 8'b01011011
                   : $digit == 4'h3 ? 8'b01001111
                   : $digit == 4'h4 ? 8'b01100110
                   : $digit == 4'h5 ? 8'b01101101
                   : $digit == 4'h6 ? 8'b01111101
                   : $digit == 4'h7 ? 8'b00000111
                   : $digit == 4'h8 ? 8'b01111111
                   : $digit == 4'h9 ? 8'b01101111
                   : $digit == 4'ha ? 8'b01110111
                   : $digit == 4'hb ? 8'b01111100
                   : $digit == 4'hc ? 8'b00111001
                   : $digit == 4'hd ? 8'b01011110
                   : $digit == 4'he ? 8'b01111001
                   : 8'b01110001;
         
  
   // Note that pipesignals assigned here can be found under /fpga_pins/fpga.
   //m5+cal_viz(@3)
   
   
   
   // Connect Tiny Tapeout outputs. Note that uio_ outputs are not available in the Tiny-Tapeout-3-based FPGA boards.
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])
   
\SV

// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0]uio_in,  uio_out, uio_oe;'])
   logic [31:0] r;
   always @(posedge clk) r <= m5_if(m5_MAKERCHIP, ['$urandom()'], ['0']);
   //assign ui_in = r[7:0];
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   
   // Or, to provide specific inputs at specific times (as for lab C-TB) ...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   initial begin
      #1  // Drive inputs on the B-phase.
         ui_in = 8'h0;
      #10 // Step 5 cycles, past reset.
         ui_in = 8'b10000101;
      #20 // Delay 10 Cycles from Cycle 5
         ui_in = 8'b00000000;
      #30 // Delay 10 Cycles from 15
         ui_in = 8'b11010000;
      // ...etc.
   end
   

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   assign passed = top.cyc_cnt > 120;
   assign failed = 1'b0;
endmodule


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
\SV



// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    m5_if_eq(m5_target, FPGA, ['/']['*'])   // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    m5_if_eq(m5_target, FPGA, ['*']['/'])
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   wire reset = ! rst_n;
   
\TLV
   /* verilator lint_off UNOPTFLAT */
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , calc)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(['"Value[0]", "Value[1]", "Value[2]", "Value[3]", "Op[0]", "Op[1]", "Op[2]", "="'])

\SV
endmodule
