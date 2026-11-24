`default_nettype none

module piezoTest(clk,RST_n,en_steer,too_fast,batt_low,piezo,
                 piezo_n,LED);

input logic clk,RST_n;
input logic en_steer;		// play Charge Fanfare every 3 seconds
input logic too_fast; 	// play 1st 3 of Charge Fanfare continuously
input logic batt_low;		// play Charge Fanfare backwards
output logic piezo;		// drives piezo
output logic piezo_n;		// drive is differential to increase volume
output logic [7:0] LED;	

wire rst_n;

  ////// instantiate your piezo block here /////
  piezo_drv #(0) iDUT(.clk(clk),.rst_n(rst_n),.en_steer(en_steer),
					  .too_fast(too_fast), .batt_low(batt_low),
					  .piezo(piezo),.piezo_n(piezo_n));
  
  rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));

  assign LED = {5'b00000,batt_low,too_fast,en_steer};
  
endmodule
