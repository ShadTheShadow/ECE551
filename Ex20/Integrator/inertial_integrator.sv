module inertial_integrator(
    input clk, 
    input rst_n, 
    input vld,                      // high for one clock cycle when new inertial readings are valid
    input signed [15:0] ptch_rt,    // 16-bit signed raw pitch rate from inertial sensor
    input signed [15:0] AZ,         // will be used for sensor fusion  (acceleration in Z direction)
    output signed [15:0] ptch       // fully compensated and “fused” 16-bit signed pitch
    );

    localparam PTCH_RT_OFFSET = 16'h0050;
    localparam AZ_OFFSET = 16'h00A0; 

    logic signed [26:0] ptch_int;           // integrating accumulator 
    logic signed [15:0] ptch_rt_comp;       // compensated pitch rate
    logic signed [15:0] AZ_comp;            // compensateed AZ
    logic signed [25:0] ptch_acc_product;   // pitch wrt the accelerometer is proportional to AZ
    logic signed [15:0] ptch_acc;           // 
    logic signed [26:0] fusion_ptch_offset; // fusion correction term

    // remove offsets from soldering to platform
    assign ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;
    assign AZ_comp = AZ - AZ_OFFSET;

    // simplified pitch wrt acceleration (small angle)
    assign ptch_acc_product = AZ_comp * $signed(327); // 327 is fudge factor
    assign ptch_acc = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]};

    // compute the fusion correction based on whether ptch_acc > integrated ptch value
    assign fusion_ptch_offset = (ptch_acc > ptch) ? 27'sd1024 : -27'sd1024;

    // pitch integrating accumulator
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            ptch_int <= 27'h0000000;
        else if (vld) 
            ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}}, ptch_rt_comp} + fusion_ptch_offset;

    assign ptch = ptch_int[26:11]; // divide by 2^11

endmodule