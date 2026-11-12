module A2D_test(clk,RST_n,SEL,LED,SCLK,SS_n,MOSI,MISO);

  input clk,RST_n;		// clk and unsynched reset from PB
  input SEL;			// from 2nd PB, cycle through outputs
  input MISO;			// from A2D
  
  output logic [7:0] LED;
  output SS_n;			// active low slave select to A2D
  output SCLK;			// SCLK to A2D SPI
  output MOSI;
  
  ////////////////////////////////////////////////////////////
  // Declare any needed internal registers (like counters) //
  //////////////////////////////////////////////////////////
  
  ///////////////////////////////////////////////////////
  // Declare any needed internal signals as type wire //
  /////////////////////////////////////////////////////

  logic en_2bit;
  logic rst_n;
  logic [11:0] lft_ld;
  logic [11:0] rght_ld;
  logic [11:0] steer_pot;
  logic [11:0] batt;

  //////////////////////////////////////////////////
  // Infer 19-bit counter to set conversion rate //
  ////////////////////////////////////////////////

  logic full;
  logic [18:0] bit_cnt;

  always_ff @(posedge clk) begin
      if (!rst_n) begin
          bit_cnt <= 19'd0;
      end
      else begin
          //Assert full and loop back
          if (bit_cnt == {19{1'b1}}) begin
              full <= 1'b1;
              bit_cnt <= 19'd0;
          end
          //Update normally
          else begin
              bit_cnt <= bit_cnt + 1;
          end
      end
  end
  
  ////////////////////////////////////////////////////////////////
  // Infer 2-bit counter to select which output to map to LEDs //
  //////////////////////////////////////////////////////////////
  logic [1:0] robin_cnt;

  always_ff @(posedge clk) begin
      if (!rst_n) begin
          robin_cnt <= 2'b00;
      end
      else if (en_2bit) begin
          //Loop back around
          if (robin_cnt == 2'b11) begin
              robin_cnt <= 2'b00;
          end
          //Update normally
          else begin
              robin_cnt <= robin_cnt + 1;
          end
      end
  end
	  
  //////////////////////////////////////////////////////
  // Infer Mux to select which output to map to LEDs //
  //////////////////////////////////////////////////// 
  always_comb begin
    case (robin_cnt)

      2'b00: begin
        LED[7:0] = lft_ld[11:4];
      end
      2'b01: begin
        LED[7:0] = rght_ld[11:4];
      end
      2'b10: begin
        LED[7:0] = steer_pot[11:4];
      end
      2'b11: begin
        LED[7:0] = batt[11:4];
      end

    endcase
  end
	
  //////////////////////
  // Instantiate DUT //
  ////////////////////  
  A2D_intf iDUT(.clk(clk),.rst_n(rst_n),.nxt(nxt),.lft_ld(lft_ld),
                .rght_ld(rght_ld),.steer_pot(steer_pot),.batt(batt),
				.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO));
			   
  ///////////////////////////////////////////////
  // Instantiate Push Button release detector //
  /////////////////////////////////////////////
  PB_release iPB(.clk(clk),.rst_n(rst_n),.PB(SEL),.released(en_2bit));
  
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////
  rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));   
	  
endmodule
  