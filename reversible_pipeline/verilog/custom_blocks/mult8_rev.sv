// This takes in mult8b_rev_wrapped, and achieves bidirectional control under signal 'dir'
/*
Wrapping Structure:
Outter Logic <-> f_/r_ Port <-> mult8b_rev_ctrl <-> pin_* bus <-> mult8b_rev_wrapped
- mult8b_rev_wrapped: the macro defined
- pin_*: physical wire connected to the macro pin, logicstate bus
- mult8b_rev_ctrl: control logic actually defined in the module
- f_/r_ Port: What the upper level(testbench) actually see
- Outter Logic: Testbench Written


*/

module mult8_rev (
`ifdef USE_POWER_PINS
    inout wire VDD,
    inout wire VSS,
`endif
    input  wire        dir,      // 0: forward  (A,B -> P,b_r_b,X_c0_b)
                                 // 1: backward (P,b_r_b,X_c0_b -> A,B)

    // Forward Interface: Used when dir == 0
    // Input: A, B
    input  wire [7:0] f_a,
    input  wire [7:0] f_b,

    // Output: P, b_r_b (reversible carries), X_c0_b
    output wire [15:0] f_p,
    output wire [7:0] f_b0_r_b,
    output wire [7:0] f_b2_r_b,
    output wire [7:0] f_b3_r_b,
    output wire [7:0] f_b4_r_b,
    output wire [7:0] f_b5_r_b,
    output wire [7:0] f_b6_r_b,
    output wire [7:0] f_b7_r_b,
    output wire [7:0] f_x_c0_b,

    // Backward Interface: Used when dir == 1
    // Input: P, b_r_b, X_c0_b
    input  wire [15:0] r_p,
    input  wire [7:0] r_b0_r_b,
    input  wire [7:0] r_b2_r_b,
    input  wire [7:0] r_b3_r_b,
    input  wire [7:0] r_b4_r_b,
    input  wire [7:0] r_b5_r_b,
    input  wire [7:0] r_b6_r_b,
    input  wire [7:0] r_b7_r_b,
    input  wire [7:0] r_x_c0_b,

    // Output: A, B (Original inputs recovered)
    output wire [7:0] r_a,
    output wire [7:0] r_b
);

    // ============================================================
    // 1) Define the physical pin (bus) connected to the macro 
    //    Allowing multiple logic-state driver
    // ============================================================
    logic [7:0] pin_a;
    logic [7:0] pin_a_not;
    logic [7:0] pin_b;
    logic [7:0] pin_b_not;
    logic [7:0] pin_x_c0_b;
    logic [7:0] pin_x_c0_b_not;

    logic [15:0] pin_p;
    logic [15:0] pin_p_not;
    logic [7:0] pin_b0_r_b;
    logic [7:0] pin_b0_r_b_not;
    logic [7:0] pin_b2_r_b;
    logic [7:0] pin_b2_r_b_not;
    logic [7:0] pin_b3_r_b;
    logic [7:0] pin_b3_r_b_not;
    logic [7:0] pin_b4_r_b;
    logic [7:0] pin_b4_r_b_not;
    logic [7:0] pin_b5_r_b;
    logic [7:0] pin_b5_r_b_not;
    logic [7:0] pin_b6_r_b;
    logic [7:0] pin_b6_r_b_not;
    logic [7:0] pin_b7_r_b;
    logic [7:0] pin_b7_r_b_not;

    // ============================================================
    // 2) Instantiating the reversible multiplier core
    // ============================================================
    mult8b_rev_wrapped u_rev (
    `ifdef USE_POWER_PINS
        .VDD     (VDD),
        .VSS     (VSS),
    `endif
        .a        (pin_a),
        .a_not    (pin_a_not),
        .b        (pin_b),
        .b_not    (pin_b_not),
        .x_c0_b   (pin_x_c0_b),
        .x_c0_b_not (pin_x_c0_b_not),

        .p        (pin_p),
        .p_not    (pin_p_not),
        .b0_r_b   (pin_b0_r_b),
        .b0_r_b_not (pin_b0_r_b_not),
        .b2_r_b   (pin_b2_r_b),
        .b2_r_b_not (pin_b2_r_b_not),
        .b3_r_b   (pin_b3_r_b),
        .b3_r_b_not (pin_b3_r_b_not),
        .b4_r_b   (pin_b4_r_b),
        .b4_r_b_not (pin_b4_r_b_not),
        .b5_r_b   (pin_b5_r_b),
        .b5_r_b_not (pin_b5_r_b_not),
        .b6_r_b   (pin_b6_r_b),
        .b6_r_b_not (pin_b6_r_b_not),
        .b7_r_b   (pin_b7_r_b),
        .b7_r_b_not (pin_b7_r_b_not)
    );

    // ============================================================
    // 3) Forward-Backward control drive
    //    This is implemented using pure combinational logic
    //
    //   - dir = 0: Forward
    //       Outside -> Macro
    //         A, B Drive pin_a/pin_b (And it's corresponding _not)
    //       Macro -> Outside
    //         pin_p, pin_b_r_b, pin_x_c0_b for outside read
    //
    //   - dir = 1: Backward
    //       Outside -> Macro
    //         P, b_r_b, X_c0_b Drives pin_p/pin_b_r_b/pin_x_c0_b (And it's corresponding _not)
    //       Macro -> Outside
    //         pin_a, pin_b for outside read
    //
    //   The logic-state bus and a one-bit dir is to ensure that each pin has only one driver at any time
    // ============================================================

    // 3.1 Forward Drive, when Dir == 0
    // Input: A, B
    assign pin_a        = (dir == 1'b0) ? f_a       : 8'h0;
    assign pin_a_not    = (dir == 1'b0) ? ~f_a      : 8'h0;

    assign pin_b        = (dir == 1'b0) ? f_b       : 8'h0;
    assign pin_b_not    = (dir == 1'b0) ? ~f_b      : 8'h0;
    // Output side P, b_r_b, x_c0_b are driven by the macro, read-only
    assign f_p       = pin_p;
    assign f_b0_r_b  = pin_b0_r_b;
    assign f_b2_r_b  = pin_b2_r_b;
    assign f_b3_r_b  = pin_b3_r_b;
    assign f_b4_r_b  = pin_b4_r_b;
    assign f_b5_r_b  = pin_b5_r_b;
    assign f_b6_r_b  = pin_b6_r_b;
    assign f_b7_r_b  = pin_b7_r_b;
    assign f_x_c0_b  = pin_x_c0_b;

    // Backward Drive, when Dir == 1
    // Input: P, b_r_b, X_c0_b
    assign pin_p        = (dir == 1'b1) ? r_p       : 16'h0;
    assign pin_p_not    = (dir == 1'b1) ? ~r_p      : 16'h0;

    assign pin_b0_r_b     = (dir == 1'b1) ? r_b0_r_b     : 8'h0;
    assign pin_b0_r_b_not = (dir == 1'b1) ? ~r_b0_r_b    : 8'h0;

    assign pin_b2_r_b     = (dir == 1'b1) ? r_b2_r_b     : 8'h0;
    assign pin_b2_r_b_not = (dir == 1'b1) ? ~r_b2_r_b    : 8'h0;

    assign pin_b3_r_b     = (dir == 1'b1) ? r_b3_r_b     : 8'h0;
    assign pin_b3_r_b_not = (dir == 1'b1) ? ~r_b3_r_b    : 8'h0;

    assign pin_b4_r_b     = (dir == 1'b1) ? r_b4_r_b     : 8'h0;
    assign pin_b4_r_b_not = (dir == 1'b1) ? ~r_b4_r_b    : 8'h0;

    assign pin_b5_r_b     = (dir == 1'b1) ? r_b5_r_b     : 8'h0;
    assign pin_b5_r_b_not = (dir == 1'b1) ? ~r_b5_r_b    : 8'h0;

    assign pin_b6_r_b     = (dir == 1'b1) ? r_b6_r_b     : 8'h0;
    assign pin_b6_r_b_not = (dir == 1'b1) ? ~r_b6_r_b    : 8'h0;

    assign pin_b7_r_b     = (dir == 1'b1) ? r_b7_r_b     : 8'h0;
    assign pin_b7_r_b_not = (dir == 1'b1) ? ~r_b7_r_b    : 8'h0;

    assign pin_x_c0_b     = (dir == 1'b1) ? r_x_c0_b     : 8'h0;
    assign pin_x_c0_b_not = (dir == 1'b1) ? ~r_x_c0_b    : 8'h0;

    assign r_a     = pin_a;
    assign r_b     = pin_b;

endmodule

`default_nettype none

// (* keep_hierarchy = "yes" *)
module mult8b_rev_wrapped (
    `ifdef USE_POWER_PINS
    inout wire VDD,
    inout wire VSS,
    `endif

    // Input ports - f_a and f_b
    inout wire [7:0] a,
    inout wire [7:0] a_not,
    inout wire [7:0] b,
    inout wire [7:0] b_not,

    // Output ports - f_p (product)
    inout wire [15:0] p,
    inout wire [15:0] p_not,

    // Reversible carry outputs - b(n)_r(m)_b signals
    inout wire [7:0] b0_r_b,
    inout wire [7:0] b0_r_b_not,
    inout wire [7:0] b2_r_b,
    inout wire [7:0] b2_r_b_not,
    inout wire [7:0] b3_r_b,
    inout wire [7:0] b3_r_b_not,
    inout wire [7:0] b4_r_b,
    inout wire [7:0] b4_r_b_not,
    inout wire [7:0] b5_r_b,
    inout wire [7:0] b5_r_b_not,
    inout wire [7:0] b6_r_b,
    inout wire [7:0] b6_r_b_not,
    inout wire [7:0] b7_r_b,
    inout wire [7:0] b7_r_b_not,

    // x(i)_c0_b output signals
    inout wire [7:0] x_c0_b,
    inout wire [7:0] x_c0_b_not

    // Additional signals (intermediates - to be filled later)
    // Placeholder for other signals that may need to be exposed
);

    // Local tie nets keep the structural macro happy during simulation
    wire [7:0] tie_lo_carry_b0;
    wire [7:0] tie_hi_carry_b0;
    wire [7:0] tie_lo_carry_b1;
    wire [7:0] tie_hi_carry_b1;
    wire [7:0] tie_lo_carry_b2;
    wire [7:0] tie_hi_carry_b2;
    wire [7:0] tie_lo_carry_b3;
    wire [7:0] tie_hi_carry_b3;
    wire [7:0] tie_lo_carry_b4;
    wire [7:0] tie_hi_carry_b4;
    wire [7:0] tie_lo_carry_b5;
    wire [7:0] tie_hi_carry_b5;
    wire [7:0] tie_lo_carry_b6;
    wire [7:0] tie_hi_carry_b6;
    wire [7:0] tie_lo_carry_b7;
    wire [7:0] tie_hi_carry_b7;

    wire [7:0] tie_lo_x_b0_f;
    wire [7:0] tie_hi_x_b0_f;
    wire [7:0] tie_lo_x_c0_f;
    wire [7:0] tie_hi_x_c0_f;
    wire       tie_lo_x0_a7_f;
    wire       tie_hi_x0_a7_f;

    assign tie_lo_carry_b0 = '0;
    assign tie_hi_carry_b0 = '1;
    assign tie_lo_carry_b1 = '0;
    assign tie_hi_carry_b1 = '1;
    assign tie_lo_carry_b2 = '0;
    assign tie_hi_carry_b2 = '1;
    assign tie_lo_carry_b3 = '0;
    assign tie_hi_carry_b3 = '1;
    assign tie_lo_carry_b4 = '0;
    assign tie_hi_carry_b4 = '1;
    assign tie_lo_carry_b5 = '0;
    assign tie_hi_carry_b5 = '1;
    assign tie_lo_carry_b6 = '0;
    assign tie_hi_carry_b6 = '1;
    assign tie_lo_carry_b7 = '0;
    assign tie_hi_carry_b7 = '1;

    assign tie_lo_x_b0_f = '0;
    assign tie_hi_x_b0_f = '1;
    assign tie_lo_x_c0_f = '0;
    assign tie_hi_x_c0_f = '1;
    assign tie_lo_x0_a7_f = 1'b0;
    assign tie_hi_x0_a7_f = 1'b1;

    (* keep *)
    mult_8b u_mult8b_rev (
        `ifdef USE_POWER_PINS
        .VDD         (VDD),
        .VSS         (VSS),
        `endif
        
        // a inputs
        .a0          (a[0]),
        .a0_not      (a_not[0]),
        .a1          (a[1]),
        .a1_not      (a_not[1]),
        .a2          (a[2]),
        .a2_not      (a_not[2]),
        .a3          (a[3]),
        .a3_not      (a_not[3]),
        .a4          (a[4]),
        .a4_not      (a_not[4]),
        .a5          (a[5]),
        .a5_not      (a_not[5]),
        .a6          (a[6]),
        .a6_not      (a_not[6]),
        .a7          (a[7]),
        .a7_not      (a_not[7]),
        
        // b inputs (b0, b1 directly; b2-b7 at end of port list)
        .b0          (b[0]),
        .b0_not      (b_not[0]),
        .b1          (b[1]),
        .b1_not      (b_not[1]),
        .b2          (b[2]),
        .b2_not      (b_not[2]),
        .b3          (b[3]),
        .b3_not      (b_not[3]),
        .b4          (b[4]),
        .b4_not      (b_not[4]),
        .b5          (b[5]),
        .b5_not      (b_not[5]),
        .b6          (b[6]),
        .b6_not      (b_not[6]),
        .b7          (b[7]),
        .b7_not      (b_not[7]),
        
        // p outputs
        .p0          (p[0]),
        .p0_not      (p_not[0]),
        .p1          (p[1]),
        .p1_not      (p_not[1]),
        .p2          (p[2]),
        .p2_not      (p_not[2]),
        .p3          (p[3]),
        .p3_not      (p_not[3]),
        .p4          (p[4]),
        .p4_not      (p_not[4]),
        .p5          (p[5]),
        .p5_not      (p_not[5]),
        .p6          (p[6]),
        .p6_not      (p_not[6]),
        .p7          (p[7]),
        .p7_not      (p_not[7]),
        .p8          (p[8]),
        .p8_not      (p_not[8]),
        .p9          (p[9]),
        .p9_not      (p_not[9]),
        .p10         (p[10]),
        .p10_not     (p_not[10]),
        .p11         (p[11]),
        .p11_not     (p_not[11]),
        .p12         (p[12]),
        .p12_not     (p_not[12]),
        .p13         (p[13]),
        .p13_not     (p_not[13]),
        .p14         (p[14]),
        .p14_not     (p_not[14]),
        .p15         (p[15]),
        .p15_not     (p_not[15]),
        
        // b0 p and q connections
        .b0_p0       (a[0]),
        .b0_p0_not   (a_not[0]),
        .b0_p1       (a[1]),
        .b0_p1_not   (a_not[1]),
        .b0_p2       (a[2]),
        .b0_p2_not   (a_not[2]),
        .b0_p3       (a[3]),
        .b0_p3_not   (a_not[3]),
        .b0_p4       (a[4]),
        .b0_p4_not   (a_not[4]),
        .b0_p5       (a[5]),
        .b0_p5_not   (a_not[5]),
        .b0_p6       (a[6]),
        .b0_p6_not   (a_not[6]),
        .b0_p7       (a[7]),
        .b0_p7_not   (a_not[7]),
        .b0_q0       (b[0]),
        .b0_q0_not   (b_not[0]),
        .b0_q1       (b[1]),
        .b0_q1_not   (b_not[1]),
        .b0_q2       (b[2]),
        .b0_q2_not   (b_not[2]),
        .b0_q3       (b[3]),
        .b0_q3_not   (b_not[3]),
        .b0_q4       (b[4]),
        .b0_q4_not   (b_not[4]),
        .b0_q5       (b[5]),
        .b0_q5_not   (b_not[5]),
        .b0_q6       (b[6]),
        .b0_q6_not   (b_not[6]),
        .b0_q7       (b[7]),
        .b0_q7_not   (b_not[7]),
        
        // b1 p and q connections
        .b1_p0       (a[0]),
        .b1_p0_not   (a_not[0]),
        .b1_p1       (a[1]),
        .b1_p1_not   (a_not[1]),
        .b1_p2       (a[2]),
        .b1_p2_not   (a_not[2]),
        .b1_p3       (a[3]),
        .b1_p3_not   (a_not[3]),
        .b1_p4       (a[4]),
        .b1_p4_not   (a_not[4]),
        .b1_p5       (a[5]),
        .b1_p5_not   (a_not[5]),
        .b1_p6       (a[6]),
        .b1_p6_not   (a_not[6]),
        .b1_p7       (a[7]),
        .b1_p7_not   (a_not[7]),
        .b1_q0       (b[0]),
        .b1_q0_not   (b_not[0]),
        .b1_q1       (b[1]),
        .b1_q1_not   (b_not[1]),
        .b1_q2       (b[2]),
        .b1_q2_not   (b_not[2]),
        .b1_q3       (b[3]),
        .b1_q3_not   (b_not[3]),
        .b1_q4       (b[4]),
        .b1_q4_not   (b_not[4]),
        .b1_q5       (b[5]),
        .b1_q5_not   (b_not[5]),
        .b1_q6       (b[6]),
        .b1_q6_not   (b_not[6]),
        .b1_q7       (b[7]),
        .b1_q7_not   (b_not[7]),
        
        // b2 p and q connections
        .b2_p0       (a[0]),
        .b2_p0_not   (a_not[0]),
        .b2_p1       (a[1]),
        .b2_p1_not   (a_not[1]),
        .b2_p2       (a[2]),
        .b2_p2_not   (a_not[2]),
        .b2_p3       (a[3]),
        .b2_p3_not   (a_not[3]),
        .b2_p4       (a[4]),
        .b2_p4_not   (a_not[4]),
        .b2_p5       (a[5]),
        .b2_p5_not   (a_not[5]),
        .b2_p6       (a[6]),
        .b2_p6_not   (a_not[6]),
        .b2_p7       (a[7]),
        .b2_p7_not   (a_not[7]),
        .b2_q0       (b[0]),
        .b2_q0_not   (b_not[0]),
        .b2_q1       (b[1]),
        .b2_q1_not   (b_not[1]),
        .b2_q2       (b[2]),
        .b2_q2_not   (b_not[2]),
        .b2_q3       (b[3]),
        .b2_q3_not   (b_not[3]),
        .b2_q4       (b[4]),
        .b2_q4_not   (b_not[4]),
        .b2_q5       (b[5]),
        .b2_q5_not   (b_not[5]),
        .b2_q6       (b[6]),
        .b2_q6_not   (b_not[6]),
        .b2_q7       (b[7]),
        .b2_q7_not   (b_not[7]),
        
        // b3 p and q connections
        .b3_p0       (a[0]),
        .b3_p0_not   (a_not[0]),
        .b3_p1       (a[1]),
        .b3_p1_not   (a_not[1]),
        .b3_p2       (a[2]),
        .b3_p2_not   (a_not[2]),
        .b3_p3       (a[3]),
        .b3_p3_not   (a_not[3]),
        .b3_p4       (a[4]),
        .b3_p4_not   (a_not[4]),
        .b3_p5       (a[5]),
        .b3_p5_not   (a_not[5]),
        .b3_p6       (a[6]),
        .b3_p6_not   (a_not[6]),
        .b3_p7       (a[7]),
        .b3_p7_not   (a_not[7]),
        .b3_q0       (b[0]),
        .b3_q0_not   (b_not[0]),
        .b3_q1       (b[1]),
        .b3_q1_not   (b_not[1]),
        .b3_q2       (b[2]),
        .b3_q2_not   (b_not[2]),
        .b3_q3       (b[3]),
        .b3_q3_not   (b_not[3]),
        .b3_q4       (b[4]),
        .b3_q4_not   (b_not[4]),
        .b3_q5       (b[5]),
        .b3_q5_not   (b_not[5]),
        .b3_q6       (b[6]),
        .b3_q6_not   (b_not[6]),
        .b3_q7       (b[7]),
        .b3_q7_not   (b_not[7]),
        
        // b4 p and q connections
        .b4_p0       (a[0]),
        .b4_p0_not   (a_not[0]),
        .b4_p1       (a[1]),
        .b4_p1_not   (a_not[1]),
        .b4_p2       (a[2]),
        .b4_p2_not   (a_not[2]),
        .b4_p3       (a[3]),
        .b4_p3_not   (a_not[3]),
        .b4_p4       (a[4]),
        .b4_p4_not   (a_not[4]),
        .b4_p5       (a[5]),
        .b4_p5_not   (a_not[5]),
        .b4_p6       (a[6]),
        .b4_p6_not   (a_not[6]),
        .b4_p7       (a[7]),
        .b4_p7_not   (a_not[7]),
        .b4_q0       (b[0]),
        .b4_q0_not   (b_not[0]),
        .b4_q1       (b[1]),
        .b4_q1_not   (b_not[1]),
        .b4_q2       (b[2]),
        .b4_q2_not   (b_not[2]),
        .b4_q3       (b[3]),
        .b4_q3_not   (b_not[3]),
        .b4_q4       (b[4]),
        .b4_q4_not   (b_not[4]),
        .b4_q5       (b[5]),
        .b4_q5_not   (b_not[5]),
        .b4_q6       (b[6]),
        .b4_q6_not   (b_not[6]),
        .b4_q7       (b[7]),
        .b4_q7_not   (b_not[7]),
        
        // b5 p and q connections
        .b5_p0       (a[0]),
        .b5_p0_not   (a_not[0]),
        .b5_p1       (a[1]),
        .b5_p1_not   (a_not[1]),
        .b5_p2       (a[2]),
        .b5_p2_not   (a_not[2]),
        .b5_p3       (a[3]),
        .b5_p3_not   (a_not[3]),
        .b5_p4       (a[4]),
        .b5_p4_not   (a_not[4]),
        .b5_p5       (a[5]),
        .b5_p5_not   (a_not[5]),
        .b5_p6       (a[6]),
        .b5_p6_not   (a_not[6]),
        .b5_p7       (a[7]),
        .b5_p7_not   (a_not[7]),
        .b5_q0       (b[0]),
        .b5_q0_not   (b_not[0]),
        .b5_q1       (b[1]),
        .b5_q1_not   (b_not[1]),
        .b5_q2       (b[2]),
        .b5_q2_not   (b_not[2]),
        .b5_q3       (b[3]),
        .b5_q3_not   (b_not[3]),
        .b5_q4       (b[4]),
        .b5_q4_not   (b_not[4]),
        .b5_q5       (b[5]),
        .b5_q5_not   (b_not[5]),
        .b5_q6       (b[6]),
        .b5_q6_not   (b_not[6]),
        .b5_q7       (b[7]),
        .b5_q7_not   (b_not[7]),
        
        // b6 p and q connections
        .b6_p0       (a[0]),
        .b6_p0_not   (a_not[0]),
        .b6_p1       (a[1]),
        .b6_p1_not   (a_not[1]),
        .b6_p2       (a[2]),
        .b6_p2_not   (a_not[2]),
        .b6_p3       (a[3]),
        .b6_p3_not   (a_not[3]),
        .b6_p4       (a[4]),
        .b6_p4_not   (a_not[4]),
        .b6_p5       (a[5]),
        .b6_p5_not   (a_not[5]),
        .b6_p6       (a[6]),
        .b6_p6_not   (a_not[6]),
        .b6_p7       (a[7]),
        .b6_p7_not   (a_not[7]),
        .b6_q0       (b[0]),
        .b6_q0_not   (b_not[0]),
        .b6_q1       (b[1]),
        .b6_q1_not   (b_not[1]),
        .b6_q2       (b[2]),
        .b6_q2_not   (b_not[2]),
        .b6_q3       (b[3]),
        .b6_q3_not   (b_not[3]),
        .b6_q4       (b[4]),
        .b6_q4_not   (b_not[4]),
        .b6_q5       (b[5]),
        .b6_q5_not   (b_not[5]),
        .b6_q6       (b[6]),
        .b6_q6_not   (b_not[6]),
        .b6_q7       (b[7]),
        .b6_q7_not   (b_not[7]),
        
        // b7 p and q connections
        .b7_p0       (a[0]),
        .b7_p0_not   (a_not[0]),
        .b7_p1       (a[1]),
        .b7_p1_not   (a_not[1]),
        .b7_p2       (a[2]),
        .b7_p2_not   (a_not[2]),
        .b7_p3       (a[3]),
        .b7_p3_not   (a_not[3]),
        .b7_p4       (a[4]),
        .b7_p4_not   (a_not[4]),
        .b7_p5       (a[5]),
        .b7_p5_not   (a_not[5]),
        .b7_p6       (a[6]),
        .b7_p6_not   (a_not[6]),
        .b7_p7       (a[7]),
        .b7_p7_not   (a_not[7]),
        .b7_q0       (b[0]),
        .b7_q0_not   (b_not[0]),
        .b7_q1       (b[1]),
        .b7_q1_not   (b_not[1]),
        .b7_q2       (b[2]),
        .b7_q2_not   (b_not[2]),
        .b7_q3       (b[3]),
        .b7_q3_not   (b_not[3]),
        .b7_q4       (b[4]),
        .b7_q4_not   (b_not[4]),
        .b7_q5       (b[5]),
        .b7_q5_not   (b_not[5]),
        .b7_q6       (b[6]),
        .b7_q6_not   (b_not[6]),
        .b7_q7       (b[7]),
        .b7_q7_not   (b_not[7]),
        
    // Tie carry signals to 0 and inverted carry to 1
    .b0_c0       (tie_lo_carry_b0[0]),
    .b0_c0_not   (tie_hi_carry_b0[0]),
    .b0_c1       (tie_lo_carry_b0[1]),
    .b0_c1_not   (tie_hi_carry_b0[1]),
    .b0_c2       (tie_lo_carry_b0[2]),
    .b0_c2_not   (tie_hi_carry_b0[2]),
    .b0_c3       (tie_lo_carry_b0[3]),
    .b0_c3_not   (tie_hi_carry_b0[3]),
    .b0_c4       (tie_lo_carry_b0[4]),
    .b0_c4_not   (tie_hi_carry_b0[4]),
    .b0_c5       (tie_lo_carry_b0[5]),
    .b0_c5_not   (tie_hi_carry_b0[5]),
    .b0_c6       (tie_lo_carry_b0[6]),
    .b0_c6_not   (tie_hi_carry_b0[6]),
    .b0_c7       (tie_lo_carry_b0[7]),
    .b0_c7_not   (tie_hi_carry_b0[7]),

    .b1_c0       (tie_lo_carry_b1[0]),
    .b1_c0_not   (tie_hi_carry_b1[0]),
    .b1_c1       (tie_lo_carry_b1[1]),
    .b1_c1_not   (tie_hi_carry_b1[1]),
    .b1_c2       (tie_lo_carry_b1[2]),
    .b1_c2_not   (tie_hi_carry_b1[2]),
    .b1_c3       (tie_lo_carry_b1[3]),
    .b1_c3_not   (tie_hi_carry_b1[3]),
    .b1_c4       (tie_lo_carry_b1[4]),
    .b1_c4_not   (tie_hi_carry_b1[4]),
    .b1_c5       (tie_lo_carry_b1[5]),
    .b1_c5_not   (tie_hi_carry_b1[5]),
    .b1_c6       (tie_lo_carry_b1[6]),
    .b1_c6_not   (tie_hi_carry_b1[6]),
    .b1_c7       (tie_lo_carry_b1[7]),
    .b1_c7_not   (tie_hi_carry_b1[7]),

    .b2_c0       (tie_lo_carry_b2[0]),
    .b2_c0_not   (tie_hi_carry_b2[0]),
    .b2_c1       (tie_lo_carry_b2[1]),
    .b2_c1_not   (tie_hi_carry_b2[1]),
    .b2_c2       (tie_lo_carry_b2[2]),
    .b2_c2_not   (tie_hi_carry_b2[2]),
    .b2_c3       (tie_lo_carry_b2[3]),
    .b2_c3_not   (tie_hi_carry_b2[3]),
    .b2_c4       (tie_lo_carry_b2[4]),
    .b2_c4_not   (tie_hi_carry_b2[4]),
    .b2_c5       (tie_lo_carry_b2[5]),
    .b2_c5_not   (tie_hi_carry_b2[5]),
    .b2_c6       (tie_lo_carry_b2[6]),
    .b2_c6_not   (tie_hi_carry_b2[6]),
    .b2_c7       (tie_lo_carry_b2[7]),
    .b2_c7_not   (tie_hi_carry_b2[7]),

    .b3_c0       (tie_lo_carry_b3[0]),
    .b3_c0_not   (tie_hi_carry_b3[0]),
    .b3_c1       (tie_lo_carry_b3[1]),
    .b3_c1_not   (tie_hi_carry_b3[1]),
    .b3_c2       (tie_lo_carry_b3[2]),
    .b3_c2_not   (tie_hi_carry_b3[2]),
    .b3_c3       (tie_lo_carry_b3[3]),
    .b3_c3_not   (tie_hi_carry_b3[3]),
    .b3_c4       (tie_lo_carry_b3[4]),
    .b3_c4_not   (tie_hi_carry_b3[4]),
    .b3_c5       (tie_lo_carry_b3[5]),
    .b3_c5_not   (tie_hi_carry_b3[5]),
    .b3_c6       (tie_lo_carry_b3[6]),
    .b3_c6_not   (tie_hi_carry_b3[6]),
    .b3_c7       (tie_lo_carry_b3[7]),
    .b3_c7_not   (tie_hi_carry_b3[7]),

    .b4_c0       (tie_lo_carry_b4[0]),
    .b4_c0_not   (tie_hi_carry_b4[0]),
    .b4_c1       (tie_lo_carry_b4[1]),
    .b4_c1_not   (tie_hi_carry_b4[1]),
    .b4_c2       (tie_lo_carry_b4[2]),
    .b4_c2_not   (tie_hi_carry_b4[2]),
    .b4_c3       (tie_lo_carry_b4[3]),
    .b4_c3_not   (tie_hi_carry_b4[3]),
    .b4_c4       (tie_lo_carry_b4[4]),
    .b4_c4_not   (tie_hi_carry_b4[4]),
    .b4_c5       (tie_lo_carry_b4[5]),
    .b4_c5_not   (tie_hi_carry_b4[5]),
    .b4_c6       (tie_lo_carry_b4[6]),
    .b4_c6_not   (tie_hi_carry_b4[6]),
    .b4_c7       (tie_lo_carry_b4[7]),
    .b4_c7_not   (tie_hi_carry_b4[7]),

    .b5_c0       (tie_lo_carry_b5[0]),
    .b5_c0_not   (tie_hi_carry_b5[0]),
    .b5_c1       (tie_lo_carry_b5[1]),
    .b5_c1_not   (tie_hi_carry_b5[1]),
    .b5_c2       (tie_lo_carry_b5[2]),
    .b5_c2_not   (tie_hi_carry_b5[2]),
    .b5_c3       (tie_lo_carry_b5[3]),
    .b5_c3_not   (tie_hi_carry_b5[3]),
    .b5_c4       (tie_lo_carry_b5[4]),
    .b5_c4_not   (tie_hi_carry_b5[4]),
    .b5_c5       (tie_lo_carry_b5[5]),
    .b5_c5_not   (tie_hi_carry_b5[5]),
    .b5_c6       (tie_lo_carry_b5[6]),
    .b5_c6_not   (tie_hi_carry_b5[6]),
    .b5_c7       (tie_lo_carry_b5[7]),
    .b5_c7_not   (tie_hi_carry_b5[7]),

    .b6_c0       (tie_lo_carry_b6[0]),
    .b6_c0_not   (tie_hi_carry_b6[0]),
    .b6_c1       (tie_lo_carry_b6[1]),
    .b6_c1_not   (tie_hi_carry_b6[1]),
    .b6_c2       (tie_lo_carry_b6[2]),
    .b6_c2_not   (tie_hi_carry_b6[2]),
    .b6_c3       (tie_lo_carry_b6[3]),
    .b6_c3_not   (tie_hi_carry_b6[3]),
    .b6_c4       (tie_lo_carry_b6[4]),
    .b6_c4_not   (tie_hi_carry_b6[4]),
    .b6_c5       (tie_lo_carry_b6[5]),
    .b6_c5_not   (tie_hi_carry_b6[5]),
    .b6_c6       (tie_lo_carry_b6[6]),
    .b6_c6_not   (tie_hi_carry_b6[6]),
    .b6_c7       (tie_lo_carry_b6[7]),
    .b6_c7_not   (tie_hi_carry_b6[7]),

    .b7_c0       (tie_lo_carry_b7[0]),
    .b7_c0_not   (tie_hi_carry_b7[0]),
    .b7_c1       (tie_lo_carry_b7[1]),
    .b7_c1_not   (tie_hi_carry_b7[1]),
    .b7_c2       (tie_lo_carry_b7[2]),
    .b7_c2_not   (tie_hi_carry_b7[2]),
    .b7_c3       (tie_lo_carry_b7[3]),
    .b7_c3_not   (tie_hi_carry_b7[3]),
    .b7_c4       (tie_lo_carry_b7[4]),
    .b7_c4_not   (tie_hi_carry_b7[4]),
    .b7_c5       (tie_lo_carry_b7[5]),
    .b7_c5_not   (tie_hi_carry_b7[5]),
    .b7_c6       (tie_lo_carry_b7[6]),
    .b7_c6_not   (tie_hi_carry_b7[6]),
    .b7_c7       (tie_lo_carry_b7[7]),
    .b7_c7_not   (tie_hi_carry_b7[7]),
        
    // Set x(i)_b0_f to 0 and x(i)_b0_f_not to 1
    .x0_b0_f     (tie_lo_x_b0_f[0]),
    .x0_b0_f_not (tie_hi_x_b0_f[0]),
    .x1_b0_f     (tie_lo_x_b0_f[1]),
    .x1_b0_f_not (tie_hi_x_b0_f[1]),
    .x2_b0_f     (tie_lo_x_b0_f[2]),
    .x2_b0_f_not (tie_hi_x_b0_f[2]),
    .x3_b0_f     (tie_lo_x_b0_f[3]),
    .x3_b0_f_not (tie_hi_x_b0_f[3]),
    .x4_b0_f     (tie_lo_x_b0_f[4]),
    .x4_b0_f_not (tie_hi_x_b0_f[4]),
    .x5_b0_f     (tie_lo_x_b0_f[5]),
    .x5_b0_f_not (tie_hi_x_b0_f[5]),
    .x6_b0_f     (tie_lo_x_b0_f[6]),
    .x6_b0_f_not (tie_hi_x_b0_f[6]),
    .x7_b0_f     (tie_lo_x_b0_f[7]),
    .x7_b0_f_not (tie_hi_x_b0_f[7]),
        
    // Set x(i)_c0_f to 0 and x(i)_c0_f_not to 1
    .x0_c0_f     (tie_lo_x_c0_f[0]),
    .x0_c0_f_not (tie_hi_x_c0_f[0]),
    .x1_c0_f     (tie_lo_x_c0_f[1]),
    .x1_c0_f_not (tie_hi_x_c0_f[1]),
    .x2_c0_f     (tie_lo_x_c0_f[2]),
    .x2_c0_f_not (tie_hi_x_c0_f[2]),
    .x3_c0_f     (tie_lo_x_c0_f[3]),
    .x3_c0_f_not (tie_hi_x_c0_f[3]),
    .x4_c0_f     (tie_lo_x_c0_f[4]),
    .x4_c0_f_not (tie_hi_x_c0_f[4]),
    .x5_c0_f     (tie_lo_x_c0_f[5]),
    .x5_c0_f_not (tie_hi_x_c0_f[5]),
    .x6_c0_f     (tie_lo_x_c0_f[6]),
    .x6_c0_f_not (tie_hi_x_c0_f[6]),
    .x7_c0_f     (tie_lo_x_c0_f[7]),
    .x7_c0_f_not (tie_hi_x_c0_f[7]),
        
    // Set x0_a7_f to 0 and x0_a7_f_not to 1
    .x0_a7_f     (tie_lo_x0_a7_f),
    .x0_a7_f_not (tie_hi_x0_a7_f),
        
    // Connect b0_r(m)_b signals to output
    .b0_r1_b     (b0_r_b[0]),
    .b0_r1_b_not (b0_r_b_not[0]),
    .b0_r2_b     (b0_r_b[1]),
    .b0_r2_b_not (b0_r_b_not[1]),
    .b0_r3_b     (b0_r_b[2]),
    .b0_r3_b_not (b0_r_b_not[2]),
    .b0_r4_b     (b0_r_b[3]),
    .b0_r4_b_not (b0_r_b_not[3]),
    .b0_r5_b     (b0_r_b[4]),
    .b0_r5_b_not (b0_r_b_not[4]),
    .b0_r6_b     (b0_r_b[5]),
    .b0_r6_b_not (b0_r_b_not[5]),
    .b0_r7_b     (b0_r_b[6]),
    .b0_r7_b_not (b0_r_b_not[6]),
    .x0_a7_b     (b0_r_b[7]),
    .x0_a7_b_not (b0_r_b_not[7]),
    
    // Connect b2_r(m)_b signals to output
    .b2_r0_b     (b2_r_b[0]),
    .b2_r0_b_not (b2_r_b_not[0]),
    .b2_r1_b     (b2_r_b[1]),
    .b2_r1_b_not (b2_r_b_not[1]),
    .b2_r2_b     (b2_r_b[2]),
    .b2_r2_b_not (b2_r_b_not[2]),
    .b2_r3_b     (b2_r_b[3]),
    .b2_r3_b_not (b2_r_b_not[3]),
    .b2_r4_b     (b2_r_b[4]),
    .b2_r4_b_not (b2_r_b_not[4]),
    .b2_r5_b     (b2_r_b[5]),
    .b2_r5_b_not (b2_r_b_not[5]),
    .b2_r6_b     (b2_r_b[6]),
    .b2_r6_b_not (b2_r_b_not[6]),
    .b2_r7_b     (b2_r_b[7]),
    .b2_r7_b_not (b2_r_b_not[7]),
    
    // Connect b3_r(m)_b signals to output
    .b3_r0_b     (b3_r_b[0]),
    .b3_r0_b_not (b3_r_b_not[0]),
    .b3_r1_b     (b3_r_b[1]),
    .b3_r1_b_not (b3_r_b_not[1]),
    .b3_r2_b     (b3_r_b[2]),
    .b3_r2_b_not (b3_r_b_not[2]),
    .b3_r3_b     (b3_r_b[3]),
    .b3_r3_b_not (b3_r_b_not[3]),
    .b3_r4_b     (b3_r_b[4]),
    .b3_r4_b_not (b3_r_b_not[4]),
    .b3_r5_b     (b3_r_b[5]),
    .b3_r5_b_not (b3_r_b_not[5]),
    .b3_r6_b     (b3_r_b[6]),
    .b3_r6_b_not (b3_r_b_not[6]),
    .b3_r7_b     (b3_r_b[7]),
    .b3_r7_b_not (b3_r_b_not[7]),
    
    // Connect b4_r(m)_b signals to output
    .b4_r0_b     (b4_r_b[0]),
    .b4_r0_b_not (b4_r_b_not[0]),
    .b4_r1_b     (b4_r_b[1]),
    .b4_r1_b_not (b4_r_b_not[1]),
    .b4_r2_b     (b4_r_b[2]),
    .b4_r2_b_not (b4_r_b_not[2]),
    .b4_r3_b     (b4_r_b[3]),
    .b4_r3_b_not (b4_r_b_not[3]),
    .b4_r4_b     (b4_r_b[4]),
    .b4_r4_b_not (b4_r_b_not[4]),
    .b4_r5_b     (b4_r_b[5]),
    .b4_r5_b_not (b4_r_b_not[5]),
    .b4_r6_b     (b4_r_b[6]),
    .b4_r6_b_not (b4_r_b_not[6]),
    .b4_r7_b     (b4_r_b[7]),
    .b4_r7_b_not (b4_r_b_not[7]),
    
    // Connect b5_r(m)_b signals to output
    .b5_r0_b     (b5_r_b[0]),
    .b5_r0_b_not (b5_r_b_not[0]),
    .b5_r1_b     (b5_r_b[1]),
    .b5_r1_b_not (b5_r_b_not[1]),
    .b5_r2_b     (b5_r_b[2]),
    .b5_r2_b_not (b5_r_b_not[2]),
    .b5_r3_b     (b5_r_b[3]),
    .b5_r3_b_not (b5_r_b_not[3]),
    .b5_r4_b     (b5_r_b[4]),
    .b5_r4_b_not (b5_r_b_not[4]),
    .b5_r5_b     (b5_r_b[5]),
    .b5_r5_b_not (b5_r_b_not[5]),
    .b5_r6_b     (b5_r_b[6]),
    .b5_r6_b_not (b5_r_b_not[6]),
    .b5_r7_b     (b5_r_b[7]),
    .b5_r7_b_not (b5_r_b_not[7]),
    
    // Connect b6_r(m)_b signals to output
    .b6_r0_b     (b6_r_b[0]),
    .b6_r0_b_not (b6_r_b_not[0]),
    .b6_r1_b     (b6_r_b[1]),
    .b6_r1_b_not (b6_r_b_not[1]),
    .b6_r2_b     (b6_r_b[2]),
    .b6_r2_b_not (b6_r_b_not[2]),
    .b6_r3_b     (b6_r_b[3]),
    .b6_r3_b_not (b6_r_b_not[3]),
    .b6_r4_b     (b6_r_b[4]),
    .b6_r4_b_not (b6_r_b_not[4]),
    .b6_r5_b     (b6_r_b[5]),
    .b6_r5_b_not (b6_r_b_not[5]),
    .b6_r6_b     (b6_r_b[6]),
    .b6_r6_b_not (b6_r_b_not[6]),
    .b6_r7_b     (b6_r_b[7]),
    .b6_r7_b_not (b6_r_b_not[7]),
    
    // Connect b7_r(m)_b signals to output
    .b7_r0_b     (b7_r_b[0]),
    .b7_r0_b_not (b7_r_b_not[0]),
    .b7_r1_b     (b7_r_b[1]),
    .b7_r1_b_not (b7_r_b_not[1]),
    .b7_r2_b     (b7_r_b[2]),
    .b7_r2_b_not (b7_r_b_not[2]),
    .b7_r3_b     (b7_r_b[3]),
    .b7_r3_b_not (b7_r_b_not[3]),
    .b7_r4_b     (b7_r_b[4]),
    .b7_r4_b_not (b7_r_b_not[4]),
    .b7_r5_b     (b7_r_b[5]),
    .b7_r5_b_not (b7_r_b_not[5]),
    .b7_r6_b     (b7_r_b[6]),
    .b7_r6_b_not (b7_r_b_not[6]),
    .b7_r7_b     (b7_r_b[7]),
    .b7_r7_b_not (b7_r_b_not[7]),
    
    // Connect x(i)_c0_b input signals
    .x0_c0_b     (x_c0_b[0]),
    .x0_c0_b_not (x_c0_b_not[0]),
    .x1_c0_b     (x_c0_b[1]),
    .x1_c0_b_not (x_c0_b_not[1]),
    .x2_c0_b     (x_c0_b[2]),
    .x2_c0_b_not (x_c0_b_not[2]),
    .x3_c0_b     (x_c0_b[3]),
    .x3_c0_b_not (x_c0_b_not[3]),
    .x4_c0_b     (x_c0_b[4]),
    .x4_c0_b_not (x_c0_b_not[4]),
    .x5_c0_b     (x_c0_b[5]),
    .x5_c0_b_not (x_c0_b_not[5]),
    .x6_c0_b     (x_c0_b[6]),
    .x6_c0_b_not (x_c0_b_not[6]),
    .x7_c0_b     (x_c0_b[7]),
    .x7_c0_b_not (x_c0_b_not[7])
    );

endmodule

