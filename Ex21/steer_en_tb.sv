// ECE551 Ex21. AI assistance: OpenAI Codex helped write and verify this TB.
// Compile with vlog -sv -timescale 1ns/1ps (no timescale directive).
module steer_en_tb;
  logic clk=0, rst_n=0;
  logic [11:0] lft_ld=0, rght_ld=0;
  wire en_steer, rider_off;
  integer checks=0, phase=0, ref_state=0, ref_count=0;
  integer s,d,q,v,a,b,seed=55121;
  integer total,delta;
  bit gt,lt,unbalanced,stepping,done,clear_expected,en_expected,off_expected;
  steer_en #(.fast_sim(1)) iDUT(.*);
  always #10 clk=~clk;

  // Integer arithmetic oracle. No DUT arithmetic/state is used by the model.
  task automatic predict;
    total=int'(lft_ld)+int'(rght_ld);
    delta=int'(lft_ld)-int'(rght_ld);
    if (delta<0) delta=-delta;
    gt=total>576; lt=total<448;
    unbalanced=4*delta>total;
    stepping=16*delta>15*total;
    done=(ref_count%32768)==32767;
    en_expected=0; off_expected=0; clear_expected=0;
    case(ref_state)
      0: begin off_expected=!gt; clear_expected=gt; end
      1: begin off_expected=lt; clear_expected=!lt && unbalanced;
               en_expected=!lt && !unbalanced && done; end
      2: begin off_expected=lt; clear_expected=!lt && stepping;
               en_expected=!lt && !stepping; end
    endcase
  endtask

  task automatic check_now;
    predict();
    if ((iDUT.sum !== total[12:0]) || (iDUT.abs_diff !== delta[12:0]) ||
        ({iDUT.sum_gt_min,iDUT.sum_lt_min,iDUT.diff_gt_1_4,iDUT.diff_gt_15_16}
          !== {gt,lt,unbalanced,stepping}) ||
        ({en_steer,rider_off,iDUT.clr_tmr,iDUT.tmr_full}
          !== {en_expected,off_expected,clear_expected,done}) ||
        (iDUT.tmr !== ref_count[25:0])) begin
      $display("FAIL phase=%0d time=%0t loads=%0d,%0d model_state=%0d timer=%0d got en/off/clr/full=%b%b%b%b expected=%b%b%b%b",
        phase,$time,lft_ld,rght_ld,ref_state,ref_count,
        en_steer,rider_off,iDUT.clr_tmr,iDUT.tmr_full,
        en_expected,off_expected,clear_expected,done);
      $stop; $finish;
    end
    checks=checks+1;
  endtask

  always @(posedge clk) begin
    if (!rst_n) begin ref_state=0; ref_count=0; end
    else begin
      check_now();
      if (clear_expected) ref_count=0;
      else ref_count=(ref_count+1)%67108864;
      case(ref_state)
        0: if(gt) ref_state=1;
        1: if(lt) ref_state=0;
           else if(!unbalanced && done) ref_state=2;
        2: if(lt) ref_state=0;
           else if(stepping) ref_state=1;
      endcase
    end
    #1; check_now();
  end

  task automatic drive(input integer left_load,right_load);
    @(negedge clk);
    lft_ld=left_load[11:0]; rght_ld=right_load[11:0];
    #1; check_now();
  endtask

  task automatic expect_status(input bit enabled,off);
    if({en_steer,rider_off} !== {enabled,off}) begin
      $display("FAIL phase=%0d time=%0t expected en/off=%b%b got=%b%b",
        phase,$time,enabled,off,en_steer,rider_off);
      $stop; $finish;
    end
  endtask

  task automatic reset_dut;
    @(negedge clk);
    rst_n=0; lft_ld=0; rght_ld=0; ref_state=0; ref_count=0;
    #1; check_now(); expect_status(0,1);
    repeat(2) @(negedge clk);
    rst_n=1;
  endtask

  task automatic qualify;
    drive(600,200);
    repeat(2) @(posedge clk);
    #2;
    drive(400,400); // stable interval starts with timer at zero
    repeat(32766) @(posedge clk);
    #2; expect_status(0,0);
    @(posedge clk); #2; expect_status(1,0);
    @(posedge clk); #2; expect_status(1,0);
  endtask

  initial begin
    reset_dut(); phase=1;
    drive(288,288); expect_status(0,1); // upper equality
    drive(289,288); expect_status(0,0); // strictly above
    drive(224,224); expect_status(0,0); // lower equality
    drive(223,224); expect_status(0,1); // strictly below
    drive(256,256); expect_status(0,1); // deadband retains off
    $display("PASS: strict weight thresholds and hysteresis");

    $display("MARK: timer qualification starts at %0t",$time);
    phase=2; reset_dut();
    drive(600,200);
    repeat(20) @(negedge clk);
    #1; expect_status(0,0);
    qualify();
    $display("PASS: imbalance clearing and exact fast timer expiration");

    $display("MARK: ratio transitions start at %0t",$time);
    phase=3;
    drive(500,300); expect_status(1,0); // exact quarter
    drive(501,299); expect_status(1,0); // quarter ignored once enabled
    drive(775,25); expect_status(1,0);  // exact 15/16
    drive(776,24); expect_status(0,0);  // exceeds 15/16
    drive(775,25); expect_status(0,0);
    qualify();
    drive(256,256); expect_status(1,0); // deadband retains on
    drive(223,224); expect_status(0,1); // direct enabled -> off
    $display("PASS: ratio boundaries, requalification, direct rider-off");

    $display("MARK: restart/reset starts at %0t",$time);
    phase=4; reset_dut(); drive(400,400);
    repeat(15000) @(negedge clk);
    drive(600,200); drive(400,400);
    repeat(20000) @(negedge clk);
    #1; expect_status(0,0); // interrupted timer must restart
    reset_dut(); qualify(); reset_dut(); // async reset from enabled
    $display("PASS: interrupted qualification and asynchronous reset");

    $display("MARK: boundary sweep starts at %0t",$time);
    phase=5;
    // Every possible sum, both ratio boundaries, both signs, legal loads.
    // Odd sums detect rounding mistakes; extremal sums detect overflow.
    for(s=0;s<=8190;s=s+1) begin
      drive(s/2,s-s/2);
      for(q=0;q<2;q=q+1) begin
        if(q==0) d=s/4; else d=15*s/16;
        for(v=-2;v<=2;v=v+1) begin
          a=(s+d+v)/2; b=s-a;
          if(a>=0 && a<=4095 && b>=0 && b<=4095) begin
            drive(a,b); drive(b,a);
          end
        end
      end
    end
    drive(4095,4095); drive(4095,0); drive(0,4095); drive(0,0);
    $display("PASS: all sums with ratio-boundary probes, both signs, full-scale loads");
    phase=6;
    for(v=0;v<5000;v=v+1) begin
      a=$random(seed)&4095; b=$random(seed)&4095; drive(a,b);
    end
    @(negedge clk); #2;
    $display("PASS: steer_en_tb - all tests passed (%0d checks)",checks);
    $stop; $finish;
  end
  initial begin
    #20000000;
    $display("FAIL: steer_en_tb timeout"); $stop; $finish;
  end
endmodule
