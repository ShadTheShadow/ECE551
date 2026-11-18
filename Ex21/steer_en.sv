// ECE551 Ex21: load-cell datapath and steering timer.
// AI assistance: OpenAI Codex helped implement and verify this wrapper and TB.
module steer_en #(
  parameter fast_sim = 1'b0
)(
  input logic clk, rst_n,
  input logic [11:0] lft_ld, rght_ld,
  output logic en_steer, rider_off
);
  localparam [12:0] MIN_RIDER_WT = 13'h200;
  localparam [12:0] WT_HYSTERESIS = 13'h040;

  logic [12:0] sum;
  logic signed [12:0] diff;
  logic [12:0] abs_diff, sum_1_4, sum_15_16;
  logic [16:0] sum_times_15;
  logic sum_gt_min, sum_lt_min, diff_gt_1_4, diff_gt_15_16;
  logic [25:0] tmr;
  logic clr_tmr, tmr_full;

  // Extend BEFORE arithmetic: two 12-bit loads can sum to 8190.
  assign sum = {1'b0, lft_ld} + {1'b0, rght_ld};
  assign diff = $signed({1'b0, lft_ld}) - $signed({1'b0, rght_ld});
  assign abs_diff = diff[12] ? $unsigned(-diff) : $unsigned(diff);
  assign sum_1_4 = sum >> 2;
  // floor(15*sum/16), retaining the fractional contribution of odd sums.
  // A 17-bit intermediate prevents overflow before the right shift.
  assign sum_times_15 = ({4'b0, sum} << 4) - {4'b0, sum};
  assign sum_15_16 = sum_times_15[16:4];
  assign sum_gt_min = sum > (MIN_RIDER_WT + WT_HYSTERESIS);
  assign sum_lt_min = sum < (MIN_RIDER_WT - WT_HYSTERESIS);
  assign diff_gt_1_4 = abs_diff > sum_1_4;
  assign diff_gt_15_16 = abs_diff > sum_15_16;

  // 2^26 clocks / 50MHz = 1.34217728 sec; fast mode uses low 15 bits.
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)
      tmr <= 26'd0;
    else if (clr_tmr)
      tmr <= 26'd0;
    else
      tmr <= tmr + 26'd1;

  assign tmr_full = fast_sim ? (&tmr[14:0]) : (&tmr);

  steer_en_SM iSM(.clk(clk), .rst_n(rst_n), .tmr_full(tmr_full),
    .sum_gt_min(sum_gt_min), .sum_lt_min(sum_lt_min),
    .diff_gt_1_4(diff_gt_1_4), .diff_gt_15_16(diff_gt_15_16),
    .clr_tmr(clr_tmr), .en_steer(en_steer), .rider_off(rider_off));
endmodule
